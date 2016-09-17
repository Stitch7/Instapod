//
//  AudioFile.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreData

struct AudioFile {

    var length: String?
    var type: String?
    var url: URL?

    func createAudioFile(fromContext context: NSManagedObjectContext) -> AudioFileManagedObject {
        let audioFile = context.createEntityWithName("AudioFile") as! AudioFileManagedObject
        audioFile.length = length
        audioFile.type = type
        audioFile.url = url?.absoluteString

        return audioFile
    }
}

extension AudioFile {
    init(managedObject: AudioFileManagedObject) {
        length = managedObject.length
        type = managedObject.type
        url = URL(string: managedObject.url!)
    }
}
