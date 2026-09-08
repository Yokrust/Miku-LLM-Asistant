#!/usr/bin/env swift
// Renders Miku from the USDZ into flat PNGs with transparency.
//
// The design treats her as a still image with an aura behind it, so the app ships
// pixels rather than a live 3D scene: no Metal work per frame, and the composition
// stays exactly what was approved in Figma.
//
//   swift MikuApp/Scripts/render-miku.swift <modelo.usdz> <carpeta-destino>

import AppKit
import SceneKit

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("uso: render-miku.swift <modelo.usdz> <destino>\n".data(using: .utf8)!)
    exit(2)
}
let modelo = URL(fileURLWithPath: args[1])
let destino = URL(fileURLWithPath: args[2])

let escena: SCNScene
do { escena = try SCNScene(url: modelo, options: [.checkConsistency: true]) }
catch { FileHandle.standardError.write("no se pudo abrir el modelo: \(error)\n".data(using: .utf8)!); exit(1) }

let raiz = escena.rootNode
let (minimo, maximo) = raiz.boundingBox
let alto = maximo.y - minimo.y
let centro = SCNVector3((minimo.x + maximo.x) / 2, (minimo.y + maximo.y) / 2, (minimo.z + maximo.z) / 2)
print("caja: \(minimo) … \(maximo)   alto=\(alto)")

// Transparent background: the aura is drawn by SwiftUI underneath, not baked in.
escena.background.contents = NSColor.clear

// Front elevation, orthographic. A perspective lens would foreshorten her legs and
// break the vertical the cover composition is built on.
let camara = SCNCamera()
camara.usesOrthographicProjection = true
camara.orthographicScale = Double(alto) * 0.56
camara.zNear = 0.01
camara.zFar = Double(alto) * 20
let nodoCamara = SCNNode()
nodoCamara.camera = camara
nodoCamara.position = SCNVector3(centro.x, centro.y, centro.z + alto * 3)
nodoCamara.look(at: centro)
raiz.addChildNode(nodoCamara)

// Soft frontal key plus ambient, so the flat render reads clean against dark glass
// without carving hard shadows the design never had.
let ambiente = SCNNode()
ambiente.light = SCNLight()
ambiente.light!.type = .ambient
ambiente.light!.intensity = 620
raiz.addChildNode(ambiente)

let clave = SCNNode()
clave.light = SCNLight()
clave.light!.type = .directional
clave.light!.intensity = 780
clave.position = SCNVector3(centro.x - alto, centro.y + alto, centro.z + alto * 2)
clave.look(at: centro)
raiz.addChildNode(clave)

guard let dispositivo = MTLCreateSystemDefaultDevice() else {
    FileHandle.standardError.write("sin dispositivo Metal\n".data(using: .utf8)!); exit(1)
}
let renderizador = SCNRenderer(device: dispositivo, options: nil)
renderizador.scene = escena
renderizador.pointOfView = nodoCamara

try? FileManager.default.createDirectory(at: destino, withIntermediateDirectories: true)

// 1x is the size the cover uses; @2x and @3x for Retina.
let altoBase = 620
for escala in [1, 2, 3] {
    let tamano = CGSize(width: altoBase * escala * 3 / 4, height: altoBase * escala)
    let imagen = renderizador.snapshot(atTime: 0, with: tamano,
                                       antialiasingMode: .multisampling4X)
    guard let tiff = imagen.tiffRepresentation,
          let mapa = NSBitmapImageRep(data: tiff),
          let png = mapa.representation(using: .png, properties: [:])
    else { continue }
    let sufijo = escala == 1 ? "" : "@\(escala)x"
    let ruta = destino.appendingPathComponent("MikuRender\(sufijo).png")
    try? png.write(to: ruta)
    print("✓ \(ruta.lastPathComponent)  \(Int(tamano.width))×\(Int(tamano.height))")
}
