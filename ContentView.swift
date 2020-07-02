//
//  ContentView.swift
//  AudioSwitching
//
//  Created by Benjamin Juarez on 6/30/20.
//  Copyright © 2020 Benjamin Juarez. All rights reserved.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        Home()
            .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Home: View {
    // state works like useState in React
    @State var isRecording = false
    @State var session: AVAudioSession!
    @State var soundRecorder: AVAudioRecorder!
    @State var soundPlayer: AVAudioPlayer!
    
    @State var alert = false
    @State var audioFiles: [URL] = []
    
    let recordSettings = [
        AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey : 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
    ]
    
    var body: some View {
        VStack {
            HStack {
                Button(action: startRecording)
                {
                    Text("Record")
                        .fontWeight(.heavy)
                        .foregroundColor(.red)
                }
                .padding(5)
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: startPlaying)
                {
                    Text("Play")
                        .fontWeight(.heavy)
                        .foregroundColor(.green)
                }
                .padding(5)
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            VStack {
                List(self.audioFiles, id: \.self) { i in
                    Button(action: {
                        do {
                            self.soundPlayer = try AVAudioPlayer(contentsOf: i)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }) {
                        Text(i.relativeString)
                    }
                }
            }
            
        }
        .alert(isPresented: self.$alert, content: { () -> Alert in
            Alert(title: Text("Error"), message: Text("Enable Access"))
        })
        .onAppear() {
            do {
                print("v stack appeared!")
                self.session = AVAudioSession.sharedInstance()
                try self.session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                
                self.session.requestRecordPermission { (status) in
                    if !status {
                        self.alert.toggle()
                    } else {
                        print("permission already granted")
                        self.getAudioFiles()
                    }
                }
            } catch {
                print("error with v stack!")
            }
        }
    }
    
    func startRecording() {
        print("recording!")
        do {
            if self.isRecording {
                self.soundRecorder.stop()
                self.isRecording.toggle()
                print("recording stopped")
                // audio files updated, so update list
                self.getAudioFiles()
                return
            }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // multiple recordings, so keep count in file name
            let filename = url.appendingPathComponent("testRecord\(self.audioFiles.count + 1).m4a")
            
            
            self.soundRecorder = try AVAudioRecorder(url: filename, settings: recordSettings)
            self.soundRecorder.record()
            self.isRecording.toggle()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startPlaying() {
        print("playing!")
        self.soundPlayer.play()
    }
    
    func getAudioFiles() {
        do {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let result = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
            
            // clear out old data for new
            self.audioFiles.removeAll()
            
            for r in result {
                self.audioFiles.append(r)
            }
            print("audio files: ")
            print(self.audioFiles)
        } catch {
            print(error.localizedDescription)
        }
    }
}
