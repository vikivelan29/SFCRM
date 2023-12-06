import { LightningElement, wire, track, api } from 'lwc';
import {  getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
import CASE_CLOSE_SLA from '@salesforce/schema/Case.Overall_Case_Closure_SLA__c';
import CASE_STAGE_SLA_1 from '@salesforce/schema/Case.Stage_SLA_1__c';
import fetchCase from '@salesforce/schema/Case.CaseNumber';
const fields = [CASE_STAGE,CASE_CLOSE_SLA,CASE_STAGE_SLA_1,fetchCase];

export default class ASF_caseClosureMileStoneNotClosed extends LightningElement {
    @api recordId;
    timer;
    wiredData;
    timerId;
    slaTimer;
    totalLeftMilliseconds;
    totalOverdueMilliseconds;       
    wiredData1;
    timerId1;
    totalLeftMilliseconds1;
    totalOverdueMilliseconds1;
    caseObj1;
    
    @wire(getRecord, { recordId: '$recordId', fields })
    caseObj;
    get numberCase(){
        return getFieldValue(this.caseObj.data, fetchCase);
    }    
}