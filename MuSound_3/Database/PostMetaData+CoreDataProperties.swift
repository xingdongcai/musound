//
//  PostMetaData+CoreDataProperties.swift
//  MuSound_3
//
//  Created by Harrison on 12/6/19.
//  Copyright © 2019 Monash University. All rights reserved.
//
//

import Foundation
import CoreData


extension PostMetaData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostMetaData> {
        return NSFetchRequest<PostMetaData>(entityName: "PostMetaData")
    }

    @NSManaged public var filename: String?
    @NSManaged public var userID: String?
    @NSManaged public var postDescription: String?

}
