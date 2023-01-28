//
//  TimeLapseFirstView.swift
//  TimeLapseMovieMaker
//
//  Created by 藤治仁 on 2023/01/28.
//

import SwiftUI

struct TimeLapseFirstView: View {
    @StateObject var viewModel = TimeLapseFirstViewModel()
    
    var body: some View {
        ZStack {
            VStack {
                List(viewModel.importFileList, id: \.self) { fileName in
                    Text("\(fileName.lastPathComponent)")
                }
                .refreshable {
                    viewModel.createImportFileList()
                }
                Button {
                    viewModel.executeTimeLapse()
                } label: {
                    Text("Make TimeLapse Movie")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
            }
            
            if viewModel.isProgress {
                Color.gray
                    .ignoresSafeArea()
                ProgressView()
            }
        }
        .onAppear {
            viewModel.createImportFileList()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TimeLapseFirstView()
    }
}
