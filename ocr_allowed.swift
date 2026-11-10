import AppKit
import Foundation
import PDFKit
import Vision
import ImageIO

func recognize(_ image: CGImage) throws -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["es-ES", "en-US"]
    request.usesLanguageCorrection = true
    try VNImageRequestHandler(cgImage: image).perform([request])
    return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

func imageFromPDFPage(_ page: PDFPage) -> CGImage? {
    let image = page.thumbnail(of: NSSize(width: 2000, height: 2600), for: .mediaBox)
    var rect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
}

let root = FileManager.default.currentDirectoryPath
let pdfs = [
    "Parcial 1 Esteban Patiño.pdf",
    "Parcial 1 Lunes-Viernes.pdf",
    "Parcial 1 Martes-Jueves.pdf",
    "Parcial 1 Viejo.pdf",
    "Parcial 1 lunes viernes solucion.pdf",
    "Parcial 2.pdf"
]
for relative in pdfs {
    let url = URL(fileURLWithPath: root).appendingPathComponent(relative)
    guard let document = PDFDocument(url: url) else { continue }
    for index in 0..<document.pageCount {
        guard let page = document.page(at: index), let image = imageFromPDFPage(page) else { continue }
        print("\n===== \(relative) PAGE \(index + 1) =====\n")
        do { print(try recognize(image)) } catch { fputs("OCR error: \(error)\n", stderr) }
    }
}

for folder in ["Parciales viejos", "Parciales viejos imagenes "] {
    let directory = URL(fileURLWithPath: root).appendingPathComponent(folder)
    guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { continue }
    while let url = enumerator.nextObject() as? URL {
        guard ["jpg", "jpeg"].contains(url.pathExtension.lowercased()) else { continue }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
        print("\n===== \(folder)/\(url.lastPathComponent) =====\n")
        do { print(try recognize(image)) } catch { fputs("OCR error: \(error)\n", stderr) }
    }
}
