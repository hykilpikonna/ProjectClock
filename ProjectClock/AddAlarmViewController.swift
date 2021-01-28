//
//  AddAlarmViewController.swift
//  ProjectClock
//
//  Created by Hykilpikonna on 1/8/21.
// and Dallon :)

import UIKit

class AddAlarmViewController: EndEditingOnReturn
{
    // Editing variables
    var alarmCell: AlarmTableCell? = nil
    var editMode: Bool { alarmCell != nil }
    var originalTime: String = ""
    
    override func viewDidLoad()
    {
        // End edit on return
        alarmNameTextField.delegate = self
        
        // Load alarm to edit if in edit mode
        if let alarmCell = alarmCell
        {
            // Toggle editing mode
            viewTitle.text = "Edit Alarm"
            
            // Convert string to Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mma"
            let date = dateFormatter.date(from: "\(alarmCell.time.text!)\(alarmCell.ampm.text!)")
            
            // Set all the original values to be edited
            timePicker.date = date!
            originalTime = String(dateFormatter.string(from: date!).dropLast(2))
            
            // Toggle proper repeats
            if let repeats = alarmCell.repeatText.text {
                if repeats == "Repeats: Weekdays" {
                    repeatWeekdaysSwitch.isOn = true
                    repeatWeekendsSwitch.isOn = false
                } else if repeats == "Repeats: Weekends" {
                    repeatWeekendsSwitch.isOn = true
                    repeatWeekdaysSwitch.isOn = false
                } else if repeats == "Repeats: Daily" {
                    repeatWeekdaysSwitch.isOn = true
                    repeatWeekendsSwitch.isOn = true
                } else {
                    repeatWeekendsSwitch.isOn = false
                    repeatWeekdaysSwitch.isOn = false
                }
            }
            
            alarmNameTextField.text = String(alarmCell.descriptionText.text!.dropFirst(2))
            updateETA()
            
            // Sets the WVM
            if let wvm = alarmCell.wvmText.text {
                for index in 0...wvms.count-1 {
                    if wvm == wvms[index].name {
                        wvmPicker.selectRow(index, inComponent: 0, animated: true)
                    }
                }
            }
        }
    }
    
    // UI: Make scroll view scrollable
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewInner: UIView!
    override func viewDidLayoutSubviews()
    {
        scrollView.addSubview(scrollViewInner)
        scrollView.contentSize = scrollViewInner.frame.size
    }
    
    // Pickers
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var wvmPicker: UIPickerView!
    @IBOutlet weak var ringtonePicker: UIPickerView!
    
    // UI Elements
    @IBOutlet weak var repeatWeekdaysSwitch: UISwitch!
    @IBOutlet weak var repeatWeekendsSwitch: UISwitch!
    @IBOutlet weak var alarmNameTextField: UITextField!
    @IBOutlet weak var timeTillAlarmLabel: UILabel!
    @IBOutlet weak var viewTitle: UILabel!
    
    /**
     Removes the currently selcted alarm.
     Returns the removed Alarm object.
     */
    @discardableResult
    func removeCurrentAlarm() -> Alarm? {
        let hours = Int(String(originalTime[...originalTime.index(originalTime.endIndex, offsetBy: -4 )]))!
        let minutes = Int(String(originalTime.suffix(2)))!
        
        // TODO : REWRITE the am/pm check, pretty sure this could work on two alarms at once
        let alarm = Alarms.fromLocal().list.first { ($0.hour == hours || $0.hour == (hours + 12)) && $0.minute == minutes }
        
        // Removes the alarm from stored alarms
        let alarmsObj = Alarms.fromLocal()
        alarmsObj.list = Alarms.fromLocal().list.filter { $0 != alarm }
        alarmsObj.localSave()
        
        return alarm
    }
    
    /**
     Called when the time for the alarm is changed.
     Sets the time away at the top of the View.
     */
    @IBAction func alarmTimeUpdated(_ sender: Any) { updateETA() }
    
    /**
     Called when the user clicks the remove button and brings them back to the home page
     */
    @IBAction func cancelAlarmButton(_ sender: Any) {
        if editMode {
            removeCurrentAlarm()
        }
        
        self.dismiss(animated: true, completion: nil)
        //might need to reset all UI elements
    }
    
    /**
     Called when the user clicks Add Alarm
     */
    @IBAction func addAlarmButton(_ sender: Any)
    {
        var oldAlarm: Alarm? = nil
        let alarm = createAlarm()
        let alarms = Alarms.fromLocal()
        
        // Check if editing alarm
        if (editMode)
        {
            oldAlarm = removeCurrentAlarm()
        }
        // Check for existing alarm
        else
        {
            if (alarms.list.contains { $0 == alarm })
            {
                msg("Sorry", "An identical or similar alarm already exists, please try again")
                return
            }
        }
        
        // Add the alarm to the list and save the list
        Alarms.fromLocal().apply { $0.list.append(alarm) }.localSave();
        
        //Schedules notification for the alarm
        if editMode
        {
            Notification.removeNotification(alarm: oldAlarm!)
        }
        Notification.scheduleNotification(alarm: alarm)
        
        // Dismiss this view
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Create alarm, but it doesn't add the alarm to the list
     */
    func createAlarm() -> Alarm
    {
        let (h, m, _) = timePicker.date.getHMS()
        
        // Create the alarm
        let alarm = Alarm(hour: h, minute: m,
                          text: alarmNameTextField.text ?? "Alarm",
                          wakeMethod: wvms[wvmPicker.selectedRow(inComponent: 0)],
                          lastActivate: Date(), alarmTone: ringtones[ringtonePicker.selectedRow(inComponent: 0)].tone)
        
        // Set alarm.repeats to correspond with what the user selects
        (0...6).forEach { alarm.repeats[$0] = false }
        if repeatWeekdaysSwitch.isOn { (1...5).forEach { alarm.repeats[$0] = true } }
        if repeatWeekendsSwitch.isOn { [0, 6].forEach { alarm.repeats[$0] = true } }
        
        return alarm
    }
    
    /**
     Dynamically the ETA label for the alarm
     */
    func updateETA() {
        let timeTill = createAlarm().nextActivate!.timeIntervalSince(Date()).str()
        timeTillAlarmLabel.text = "Going off in \(timeTill)"
    }
}

class WVMDataSource: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource
{
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        delegate = self
        dataSource = self
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ v: UIPickerView, numberOfRowsInComponent: Int) -> Int
    {
        return wvms.count
    }
    
    func pickerView(_ v: UIPickerView, titleForRow r: Int, forComponent: Int) -> String?
    {
        return wvms[r].name + " - " + wvms[r].desc
    }
}


class RingtonesDataSource: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource
{
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        delegate = self
        dataSource = self
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ v: UIPickerView, numberOfRowsInComponent: Int) -> Int
    {
        return ringtones.count
    }

    func pickerView(_ v: UIPickerView, titleForRow r: Int, forComponent: Int) -> String?
    {
        return ringtones[r].name
        
    }
}
 
