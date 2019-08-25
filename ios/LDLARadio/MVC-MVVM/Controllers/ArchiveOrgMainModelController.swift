//
//  ArchiveOrgMainModelController.swift
//  LDLARadio
//
//  Created by fox on 11/08/2019.
//  Copyright © 2019 Mobile Patagonia. All rights reserved.
//

import Foundation
import JFCore
import AlamofireCoreData


class ArchiveOrgMainModelController: BaseController {
    
    fileprivate var mainModel : CatalogViewModel? = nil

    override init() { }
    
    init(withCatalogViewModel catalogViewModel: CatalogViewModel?) {
        mainModel = catalogViewModel
    }

    override func numberOfSections() -> Int {
        var n = 0
        if let model = mainModel {
            n = model.sections.count
            n += (model.audios.count > 0 ? 1 : 0)
        }
        return n
    }

    override func prompt() -> String {
        return AudioViewModel.ControllerName.archiveOrg.rawValue
    }
    
    override func numberOfRows(inSection section: Int) -> Int {
        var count : Int = 0
        if let model = mainModel {
            if section < model.sections.count {
                let subModel = model.sections[section]
                print ("\(subModel.title) \((subModel.isExpanded ?? false) ? "-" : "+")")
                if subModel.isExpanded == false {
                    return 0
                }
                count = subModel.sections.count + subModel.audios.count
            }
            else {
                count = model.audios.count
            }
        }
        return count > 0 ? count : 2
    }

    override func modelInstance(inSection section: Int) -> CatalogViewModel? {
        if let model = mainModel,
            section < model.sections.count {
            return model.sections[section]
        }
        return mainModel
    }

    override func model(forSection section: Int, row: Int) -> Any? {
        if let model = mainModel {
            if section < model.sections.count {
                let subModel = model.sections[section]
                if row < (subModel.sections.count + subModel.audios.count) {
                    if row < subModel.sections.count {
                        return subModel.sections[row]
                    }
                    let audioRow = row - subModel.sections.count
                    if audioRow < subModel.audios.count {
                        return subModel.audios[audioRow]
                    }
                }
            }
            else {
                if row < model.audios.count {
                    return model.audios[row]
                }
            }
        }
        return nil
    }

    override func heightForRow(at section: Int, row: Int) -> CGFloat {
        let subModel = model(forSection: section, row: row)
        if let audioModel = subModel as? AudioViewModel {
            return CGFloat(audioModel.height())
        }
        return CGFloat(CatalogViewModel.cellheight)
    }
    
    private func updateModels() {
        if let doc = ArchiveDoc.search(byIdentifier: mainModel?.id) {
            mainModel = CatalogViewModel(archiveDoc: doc, superTree: "")
        }
        lastUpdated = ArchiveCollection.lastUpdated()
    }
    

    override func privateRefresh(isClean: Bool = false,
                                 prompt: String = "Archive.org",
                                 finishClosure: ((_ error: JFError?) -> Void)? = nil)
    {
        
        let doc = ArchiveDoc.search(byIdentifier: mainModel?.id)
        
        if isClean == false {
            if doc?.detail?.archiveFiles?.count ?? 0 > 0 {
                
                mainModel = CatalogViewModel(archiveDoc: doc, superTree: "")
                
                lastUpdated = ArchiveCollection.lastUpdated()
                finishClosure?(nil)
                return
            }
        }
        
        RestApi.instance.context?.performAndWait {
            
            RestApi.instance.requestARCH(usingUrl: doc?.urlString(), type: ArchiveDetail.self) { error, detail in
                
                let archiveDoc = ArchiveDoc.search(byIdentifier: doc?.identifier)
                detail?.extractFiles()
                archiveDoc?.detail = detail
                
                let meta = ArchiveMeta.search(byCollectionIdentifier: self.mainModel?.parentId)
                archiveDoc?.response?.meta = meta
                CoreDataManager.instance.save()
                self.updateModels()
                
                DispatchQueue.main.async {
                    finishClosure?(error)
                }
            }
        }
    }

    internal override func expanding(model: CatalogViewModel?, section: Int, incrementPage: Bool, startClosure: (() -> Void)? = nil, finishClosure: ((_ error: JFError?) -> Void)? = nil) {
        
        if let isExpanded = model?.isExpanded {
            model?.isExpanded = !isExpanded
        }
        
        finishClosure?(nil)
    }
}