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
    var url: String?

    func createAudioFile(fromContext context: NSManagedObjectContext) -> AudioFileManagedObject {
        let audioFile = context.createEntityWithName("AudioFile") as! AudioFileManagedObject
        audioFile.length = length
        audioFile.type = type
        audioFile.url = url

        return audioFile
    }
}