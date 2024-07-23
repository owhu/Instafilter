//
//  ContentView.swift
//  Instafilter
//
//  Created by Oliver Hu on 7/17/24.
//

import PhotosUI
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import StoreKit

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 3.0
    @State private var filterScale = 5.0
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var showingFilters = false
    let context = CIContext()
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)

                Spacer()
                if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
                    HStack {
                        Text("Intensity")
                        Slider(value: $filterIntensity)
                            .onChange(of: filterIntensity, applyProcessing)
                            .disabled(processedImage == nil)
                    }
                    
                }
                
                if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                    HStack {
                        Text("Radius")
                        Slider(value: $filterRadius, in: 0...200)
                            .onChange(of: filterRadius, applyProcessing)
                            .disabled(processedImage == nil)
                    }
                }
                
                if currentFilter.inputKeys.contains(kCIInputScaleKey) {
                    HStack {
                        Text("Scale")
                        Slider(value: $filterScale, in: 0...10)
                            .onChange(of: filterScale, applyProcessing)
                            .disabled(processedImage == nil)
                    }
                    
                }
                
            

                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(processedImage == nil)

                    Spacer()

                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    }
                }
                
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("BokehBlur") { setFilter(CIFilter.bokehBlur()) }
                Button("Monochrome") { setFilter(CIFilter.colorMonochrome()) }
                Button("Bloom") { setFilter(CIFilter.bloom()) }
                Button("Cancel", role: .cancel) { }
            }
        }
        
        //        .onAppear(perform: loadImage)
//        .onChange(of: pickerItems) {
//            Task {
//                selectedImages.removeAll()
//                
//                for item in pickerItems {
//                    if let loadedImage = try await item.loadTransferable(type: Image.self) {
//                        selectedImages.append(loadedImage)
//                    }
//                }
//            }
//        }
    }
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }

            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }

        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        filterCount += 1

        if filterCount >= 20 {
            requestReview()
            filterCount = 0
        }
    }
    
    
    //    func loadImage() {
    //        let inputImage = UIImage(resource: .example)
    //        let beginImage = CIImage(image: inputImage)
    //
    //        let context = CIContext()
    //        let currentFilter = CIFilter.photoEffectChrome()
    //
    //        currentFilter.inputImage = beginImage
    //
    //        let amount = 1.0
    //
    //        let inputKeys = currentFilter.inputKeys
    //
    //        if inputKeys.contains(kCIInputIntensityKey) {
    //            currentFilter.setValue(amount, forKey: kCIInputIntensityKey) }
    //        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(amount * 200, forKey: kCIInputRadiusKey) }
    //        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(amount * 10, forKey: kCIInputScaleKey) }
    //        if inputKeys.contains(kCIInputSharpnessKey) { currentFilter.setValue(amount * 10, forKey: kCIInputScaleKey) }
    //
    //
    //        // get a CIImage from our filter or exit if that fails
    //        guard let outputImage = currentFilter.outputImage else { return }
    //
    //        // attempt to get a CGImage from our CIImage
    //        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
    //
    //        // convert that to a UIImage
    //        let uiImage = UIImage(cgImage: cgImage)
    //
    //        // and convert that to a SwiftUI image
    //        image = Image(uiImage: uiImage)
    //    }
}

#Preview {
    ContentView()
}
