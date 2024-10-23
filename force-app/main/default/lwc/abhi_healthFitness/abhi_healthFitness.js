import { LightningElement,api } from 'lwc';
import fitLevel from '@salesforce/label/c.ABHI_Fitness_Level';
import fitAppointment from '@salesforce/label/c.ABHI_Fitness_Appointment';
import activeDays from '@salesforce/label/c.ABHI_Active_Days';
import activeAge from '@salesforce/label/c.ABHI_HHS_Active_Age';
import appReg from '@salesforce/label/c.ABHI_Health_Return_App_Reg';
import devices from '@salesforce/label/c.ABHI_Devices';
import activeEvent from '@salesforce/label/c.Active_Day_Events';
export default class Abhi_healthFitness extends LightningElement {
   
    @api recordId;
    
    label = {
        fitLevel,
        fitAppointment,
        activeDays,
        activeAge,
        appReg,
        devices,
        activeEvent
    };

    activeSectionMessage = '';
    tabContent = '';
    refreshTab(event) {
        this.activeSectionMessage =
            'Open section name:  ' + event.detail.openSections;
    }
    handleActive(event) {
        const tab = event.target;
        this.tabContent = `Tab ${event.target.value} is now active`;
    }
}