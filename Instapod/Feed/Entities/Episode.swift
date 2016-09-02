//
//  Episode.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreData

struct Episode {

    var author: String?
    var content: String?
    var desc: String?
    var duration: String?
    var link: String?
    var pubDate: NSDate?
    var subtitle: String?
    var summary: String?
    var title: String?
    //    var chapters: NSSet?
    var image: Image?
    var audioFile: AudioFile?

    func createEpisode(fromContext context: NSManagedObjectContext) -> EpisodeManagedObject {
        let episode = context.createEntityWithName("Episode") as! EpisodeManagedObject
        episode.author = author
        episode.content = content
        episode.desc = desc
        episode.duration = duration
        episode.link = link
        episode.pubDate = pubDate
        episode.subtitle = subtitle
        episode.summary = summary
        episode.title = title
        //        episode.chapters = chapters
        episode.image = image?.createImage(fromContext: context)
        episode.audioFile = audioFile?.createAudioFile(fromContext: context)

        return episode
    }
}
