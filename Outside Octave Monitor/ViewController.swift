//
//  ViewController.swift
//  Outside Octave Monitor
//
//  Copyright 2020 Ryan Bell (MIT License)
//

import AudioKit
import Cocoa

class ViewController: NSViewController, AKMIDIListener {
    @IBOutlet private var outputTextView: NSTextView!
    @IBOutlet private var sourcePopUpButton: NSPopUpButton!
    var midi = AudioKit.midi
    
    // Monitor MIDI notes held (21-108) with unison voice support
    var statusMidiNote = Array(repeating: 0, count: 88) // 0=A0, 1=Bb0, 2=C0...
    var statusNote = Array(repeating: 0, count: 12) // 0=A, 1=Bb, 2=C...
    let intervalMonitored = 13 // Outside octave (flat 9)
    let intervalException = 10 // (minor 7)
    let hasExceptionTranspositions = true // Allow exceptions at any octave
    let intervalName = "Outside octave"
    let checkNoteOn = true
    let checkNoteOff = true
    
    let notes = [
        "A0", "Bb0", "B0", "C1", "Db1", "D1", "Eb1", "E1", "F1", "Gb1", "G1", "Ab1",
        "A1", "Bb1", "B1", "C2", "Db2", "D2", "Eb2", "E2", "F2", "Gb2", "G2", "Ab2",
        "A2", "Bb2", "B2", "C3", "Db3", "D3", "Eb3", "E3", "F3", "Gb3", "G3", "Ab3",
        "A3", "Bb3", "B3", "C4", "Db4", "D4", "Eb4", "E4", "F4", "Gb4", "G4", "Ab4",
        "A4", "Bb4", "B4", "C5", "Db5", "D5", "Eb5", "E5", "F5", "Gb5", "G5", "Ab5",
        "A5", "Bb5", "B5", "C6", "Db6", "D6", "Eb6", "E6", "F6", "Gb6", "G6", "Ab6",
        "A6", "Bb6", "B6", "C7", "Db7", "D7", "Eb7", "E7", "F7", "Gb7", "G7", "Ab7",
        "A7", "Bb7", "B7", "C8"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        midi.addListener(self)

        sourcePopUpButton.removeAllItems()
        sourcePopUpButton.addItems(withTitles: midi.inputNames)
        
        if (midi.inputNames.count > 0) {
            midi.openInput(name: midi.inputNames[0])
        }
    }
    
    func checkForOutsideOctaves() {
        // Perform interval check
        for i in 0...88-intervalMonitored {
            if (statusMidiNote[i] > 0 && statusMidiNote[i+intervalMonitored] > 0) {
                let hasExceptionMidiNote = statusMidiNote[i+intervalException] > 0 // Has exact MIDI note
                let hasExceptionNote = statusNote[(i + intervalException) % 12] > 0 // Has note at any octave
                
                // Log the interval monitored if the exception rule is not met
                if (!hasExceptionMidiNote || !(hasExceptionNote && hasExceptionTranspositions)) {
                    updateText("\(intervalName): \(notes[i]) \(notes[i+intervalMonitored])")
                }
            }
        }
    }
    
    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel,
                            portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        if (noteNumber >= 21 && noteNumber <= 108) {
            statusMidiNote[Int(noteNumber-21)] += 1
            statusNote[Int(noteNumber-21) % 12] += 1
            if (checkNoteOn) {
                checkForOutsideOctaves()
            }
        }
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel,
                             portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        if (noteNumber >= 21 && noteNumber <= 108) {
            if (checkNoteOff) {
                checkForOutsideOctaves()
            }
            statusMidiNote[Int(noteNumber-21)] = max(statusMidiNote[Int(noteNumber-21)] - 1, 0)
            statusNote[Int(noteNumber-21) % 12] -= 1
        }
    }

    func updateText(_ input: String) {
        DispatchQueue.main.async(execute: {
            self.outputTextView.string = "\(input)\n\(self.outputTextView.string)"
        })
    }

    @IBAction func sourceChanged(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem > 0 {
            midi.closeAllInputs()
            midi.openInput(name: midi.inputNames[sender.indexOfSelectedItem - 1])
        }
    }

    @IBAction func resetStatus(_ sender: Any) {
        // Reset monitoring
        statusMidiNote = Array(repeating: 0, count: 88)
        statusNote = Array(repeating: 0, count: 12)
        DispatchQueue.main.async(execute: {
            self.outputTextView.string = ""
        })
    }
}
