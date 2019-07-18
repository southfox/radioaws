//
//  CatalogTableViewModel.swift
//  LDLARadio
//
//  Created by fox on 17/07/2019.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

import Foundation

struct CatalogTableViewModel {
    var title : String = ""
    var prompt : String = ""
    var rows : Int = 1
    var sections = [String]()
    var elements = [String:[Any]]()
    var defaultElements = [String:[Any]]()
    var heights = [String:[NSNumber]]()

    init() {
    }

    init(catalog: CatalogViewModel, parentTitle: String? = "Radio Time") {
        prompt = parentTitle ?? "Radio Time"
        title = catalog.title
        for section in catalog.sections {
            sections.append(section.title)
            
            var sectionDefault = defaultElements[section.title] ?? [Any]()
            var sectionElements = elements[section.title] ?? [Any]()
            var heightElements = heights[section.title] ?? [NSNumber]()
            if section.sections.count > 0 {
                sectionElements.append(contentsOf: section.sections)
                for _ in section.sections {
                    heightElements.append(NSNumber(44))
                }
                heights[section.title] = heightElements
            }
            if section.audios.count > 0 {
                sectionElements.append(contentsOf: section.audios)
                for _ in section.audios {
                    heightElements.append(NSNumber(75))
                }
            }
            if sectionElements.count == 0 {
                sectionDefault.append(section)
                heightElements.append(NSNumber(75))
            }
            elements[section.title] = sectionElements
            heights[section.title] = heightElements
            defaultElements[section.title] = sectionDefault
        }
        if catalog.audios.count > 0 {
            sections.append(catalog.title)

            var audioElements = elements[catalog.title] ?? [Any]()
            audioElements.append(contentsOf: catalog.audios)
            var heightElements = heights[catalog.title] ?? [NSNumber]()
            for _ in catalog.audios {
                heightElements.append(NSNumber(75))
            }
            elements[catalog.title] = audioElements
            heights[catalog.title] = heightElements
        }
    }
    
    func titleForHeader(inSection section: Int) -> String {
        if section < sections.count {
            return sections[section]
        }
        return ""
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        if section < sections.count {
            let sectionName = sections[section]
            let count = elements[sectionName]?.count ?? 0
            if count > 0 {
                return count
            }
        }
        return 1
    }
    
    func elements(forSection section: Int, row: Int) -> Any? {
        
        if section < sections.count {
            let sectionName = sections[section]
            if let objects = elements[sectionName] {
                if row < objects.count {
                    return objects[row]
                }
            }
            return defaultElements[sectionName]?.first
        }
        return nil
    }
 
    func heightForRow(at section: Int, row: Int) -> Float {
        if section < sections.count {
            let sectionName = sections[section]
            if let objects = heights[sectionName] {
                if row < objects.count {
                    return objects[row].floatValue
                }
            }
        }
        return 44
    }
    
}
