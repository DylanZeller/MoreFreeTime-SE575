//
//  ScheduleControllerViewController.swift
//  MoreFreeTime
//
//  Created by Dylan Zeller on 11/25/18.
//  Copyright © 2018 Dylan Zeller. All rights reserved.
//

import UIKit
import SQLite
class ScheduleControllerViewController: UIViewController/*, UITableViewDelegate, UITableViewDataSource*/ {
    
    var database : Connection!
    
    let eventsTable = Table("events")
    let id = Expression<Int>("id")
    let eventTitle = Expression<String>("title")
    let eventStartDate = Expression<String>("startDate")
    let eventStartTime = Expression<String>("startTime")
    let eventEndDate = Expression<String>("endDate")
    let eventEndTime = Expression<String>("endTime")
    let eventLocation = Expression<String>("location")
    let eventDescription = Expression<String?>("description")

    
    
    @IBOutlet weak var dateLabel: UILabel!
    
    var dateObserver : NSObjectProtocol?
    var newEventObserver : NSObjectProtocol?
    
    var formattedDate: String {
        get {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: Date())
        }
    }
    
    var formattedShortDate : String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    var currentDate : String?
    var currentShortDate : String?
    var newEvent : Event?
    var events : [Event] = []
    
    @IBOutlet weak var eventsViewer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // This will open and set the global database
        do {
            let docDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = docDirectory.appendingPathComponent("testing1").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        addObservers()
        deleteTable()
        createTable()
        getTodaysEvents()
        
        currentDate = formattedDate
        currentShortDate = formattedShortDate
        dateLabel.text = currentDate
        //Pull all events from Database that correspond to date
        

    }
    
    func addObservers() {
        dateObserver = NotificationCenter.default.addObserver(forName: .saveStartDateTime, object: nil, queue: OperationQueue.main) {
            (notification) in let dateVc = notification.object as! DatePopupViewController
            self.dateLabel.text = dateVc.formattedDateLong
            self.currentDate = dateVc.formattedDateLong
            self.currentShortDate = dateVc.formattedDate
            //When the date changes, also clear the events and populate with the current dates events
        }
        newEventObserver = NotificationCenter.default.addObserver(forName: .saveNewEvent, object: nil, queue: OperationQueue.main) {
            (notification) in let newEvent = notification.object as! Event
            self.insertEvent(e: newEvent)
            print("Events List:")
            self.getTodaysEvents()
            print(self.events[0].getTimeInMinutes())
            self.sortEvents()
        }
        //print("added observer")
    }
    
    func getTodaysEvents() {
        var todaysEvents : [Event] = []
        do {
            let dbEvents = try self.database.prepare(eventsTable)
            for dbEvent in dbEvents {
                if dbEvent[self.eventStartDate].isEqual(currentShortDate) {
                    let event = Event(title: dbEvent[self.eventTitle], startDate: dbEvent[self.eventStartDate], startTime: dbEvent[self.eventStartTime], endDate: dbEvent[self.eventEndDate], endTime: dbEvent[self.eventEndTime], location: dbEvent[self.eventLocation], description: dbEvent[self.eventDescription]!)
                    todaysEvents.append(event)
                }
            }
        } catch {
            print(error)
        }
        self.events = todaysEvents
    }
    
    func sortEvents() {
        events = events.sorted(by: { $0 < $1 })
    }
    
    func createTable() {
        let createTable = self.eventsTable.create { (table) in
            table.column(self.id, primaryKey: true)
            table.column(self.eventTitle)
            table.column(self.eventStartDate)
            table.column(self.eventStartTime)
            table.column(self.eventEndDate)
            table.column(self.eventEndTime)
            table.column(self.eventLocation)
            table.column(self.eventDescription)
        }
        
        do {
            try self.database.run(createTable)
            print("Created Table")
        } catch {
            print(error)
        }
    }
    
    func deleteTable() {
        let deleteTable = self.eventsTable.delete()
        do {
            try self.database.run(deleteTable)
        } catch {
            print(error)
        }
    }
    
    func deleteEvent() {
        let event = self.eventsTable.filter(self.id == 1)
        let deleteEvent = event.delete()
        do {
            try self.database.run(deleteEvent)
        } catch {
            print(error)
        }
    }
    
    func insertEvent(e : Event) {
        let insertEvent = self.eventsTable.insert(self.eventTitle <- e.title, self.eventStartDate <- e.startDate, self.eventStartTime <- e.startTime, self.eventEndDate <- e.endDate, self.eventEndTime <- e.endTime, self.eventLocation <- e.location, self.eventDescription <- e.description)
        do {
            try self.database.run(insertEvent)
            print("Inserted Event")
        } catch {
            print("Error")
        }
    }
    
    func insertGenericEvent() {
        let insertEvent = self.eventsTable.insert(self.eventTitle <- "Name", self.eventStartDate <- "EventStartDate", self.eventStartTime <- "EventStartTime",self.eventEndDate <- "EventEndDate", self.eventEndTime <- "EventEndTime", self.eventLocation <- "EventLocation", self.eventDescription <- "EventDescription")
        
        do {
            try self.database.run(insertEvent)
            print("Inserted Event")
        } catch {
            print("Error")
        }
    }
    
    func updateEvent() {
        let event = self.eventsTable.filter(self.id == 1)
        let updateEvent = event.update(self.eventLocation <- "Meet me here.")
        do {
            try self.database.run(updateEvent)
        } catch {
            print(error)
        }
    }
    
    func listEvents() {
        do {
            let events = try self.database.prepare(eventsTable)
            for event in events {
                print("eventId: \(event[self.id]), title: \(event[self.eventTitle]), startDate: \(event[self.eventStartDate]), startTime: \(event[self.eventStartTime]), endDate: \(event[self.eventEndDate]), endTime: \(event[self.eventEndTime]),location: \(event[self.eventLocation]), description: \(event[self.eventDescription]!),")
            }
        } catch {
            print(error)
        }
    }
    
    func populateEvents() {
        //This is where the events in the page will be populated from
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCurrentDatePopupView" {
            let popup = segue.destination as! DatePopupViewController
            popup.isStart = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let dateObserver = dateObserver {
            NotificationCenter.default.removeObserver(dateObserver)
        }
        if let newEventObserver = newEventObserver {
            NotificationCenter.default.removeObserver(newEventObserver)
        }
    }
}