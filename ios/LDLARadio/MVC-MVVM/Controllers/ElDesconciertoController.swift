//
//  ElDesconciertoController.swift
//  LDLARadio
//
//  Created by fox on 28/07/2019.
//  Copyright © 2019 Mobile Patagonia. All rights reserved.
//

import Foundation
import JFCore
import AlamofireCoreData

class ElDesconciertoController: BaseController {

    fileprivate var models = [SectionViewModel]()

    override init() { }

    override func numberOfSections() -> Int {
        return models.count
    }

    override func title() -> String {
        return AudioViewModel.ControllerName.Desconcierto.rawValue
    }

    override func numberOfRows(inSection section: Int) -> Int {
        var rows: Int = 0
        if section < models.count {
            let model = models[section]
            if model.isCollapsed == true {
                return 0
            }
            rows = model.audios.count
        }
        return rows > 0 ? rows : 1
    }

    override func modelInstance(inSection section: Int) -> SectionViewModel? {
        if section < models.count {
            let model = models[section]
            return model
        }
        return models.first
    }

    override func model(forSection section: Int, row: Int) -> Any? {
        if section < models.count {
            let model = models[section]
            if row < model.audios.count {
                return model.audios[row]
            }
        }
        return nil
    }

    private func updateModels() {
        if let streams = Desconcierto.all()?.filter({ (stream) -> Bool in
            stream.streamUrl1?.isEmpty == false
        }) {
            func isCollapsed(des: Desconcierto?) -> Bool {
                return models.filter { (catalog) -> Bool in
                    (catalog.isCollapsed ?? true) && des?.date == catalog.title.text
                }.isEmpty == false
            }
            models = streams.map({ SectionViewModel(desconcierto: $0, isAlreadyCollapsed: isCollapsed(des: $0)) }).filter({ (model) -> Bool in
                model.urlString()?.isEmpty == false
            })
        }
        lastUpdated = Desconcierto.lastUpdated()
    }

    override func privateRefresh(isClean: Bool = false,
                                 prompt: String,
                                 finishClosure: ((_ error: JFError?) -> Void)? = nil) {

        if isClean == false {
            updateModels()
            if !models.isEmpty {
                finishClosure?(nil)
                return
            }
        }

        RestApi.instance.context?.performAndWait {

            Desconcierto.clean()

            RestApi.instance.requestLDLA(usingQuery: "/desconciertos.json", type: Many<Desconcierto>.self) { error, _ in

                if error != nil {
                    CoreDataManager.instance.rollback()
                } else {
                    CoreDataManager.instance.save()
                }
                self.updateModels()

                DispatchQueue.main.async {
                    finishClosure?(error)
                }
            }
        }
    }

    func changeCatalogBookmark(section: Int) {
        if section < models.count {
            let model = models[section]
            Audio.changeCatalogBookmark(model: model)
        }
    }

    internal override func expanding(model: SectionViewModel?, section: Int, incrementPage: Bool, startClosure: (() -> Void)? = nil, finishClosure: ((_ error: JFError?) -> Void)? = nil) {

        if let isCollapsed = model?.isCollapsed {
            models[section].isCollapsed = !isCollapsed
        }

        finishClosure?(nil)
    }

}
