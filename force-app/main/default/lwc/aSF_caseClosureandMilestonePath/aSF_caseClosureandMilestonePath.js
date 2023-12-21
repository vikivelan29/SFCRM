import { LightningElement, wire, track, api } from 'lwc';
import {  getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getDataOnLoad from '@salesforce/apex/ASF_ClosedMilestoneTimeController.getDataOnLoad';
import getDataOnLoadSLA from '@salesforce/apex/ASF_StageBasedMilestoneTimerController.getDataOnLoad';
import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
import CASE_CLOSE_SLA from '@salesforce/schema/Case.Overall_Case_Closure_SLA__c';
import CASE_STAGE_SLA_1 from '@salesforce/schema/Case.Stage_SLA_1__c';
import fetchCase from '@salesforce/schema/Case.CaseNumber';
import { refreshApex } from '@salesforce/apex';
const fields = [CASE_STAGE,CASE_CLOSE_SLA,CASE_STAGE_SLA_1,fetchCase];

export default class ASF_caseClosureandMilestonePath extends LightningElement {
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
    within;
    outside;
    stageWithin;
    stageOutside;
    
    @wire(getRecord, { recordId: '$recordId', fields })
    caseObj;
    get caseStage() {
        return getFieldValue(this.caseObj.data, CASE_STAGE);
    } 
    get caseCloseSLA() {
        return getFieldValue(this.caseObj.data, CASE_CLOSE_SLA);
    } 
    get caseStageSLA1() {
        return getFieldValue(this.caseObj.data, CASE_STAGE_SLA_1);
    } 
    get numberCase(){
        return getFieldValue(this.caseObj.data, fetchCase);
    }
     @wire(getDataOnLoad, {caseId: '$recordId',caseStage:'$caseStage'}) 
    wiredDataFunc(result){
        this.wiredData = result;

        if(result.data){
            var data = result.data;
            console.log('data==',data);
            if( data.leftTotalSec && data.leftTotalSec > 0){
                this.totalLeftMilliseconds = data.leftTotalSec;
            }else if(data.overdueTotalSec && data.overdueTotalSec > 0){
                this.totalOverdueMilliseconds = data.overdueTotalSec;
            }
            
            clearInterval(this.timerId);
            
            if(data?.businessHourWorking){
                this.start();
            }else{
                if(this.totalLeftMilliseconds >= 1000){
                    this.timer = this.msToTime(this.totalLeftMilliseconds);
                    this.timer = this.timer + 'left';
                    this.within = true;
                   this.outside = false;
                }else if(this.totalOverdueMilliseconds >= 1000){
                    this.timer = this.msToTime(this.totalOverdueMilliseconds);
                    this.timer = this.timer + 'overdue';
                    this.outside = true;
                    this.within = false;
                } 
            }
        }
        if(result.error){
            console.log(result.error);
        }
    } 
    start() {
        this.timerId = setInterval(()=> {
            if(this.totalLeftMilliseconds < 1000 && this.totalLeftMilliseconds > 0){
                this.timer =  '0 sec left';
                this.totalLeftMilliseconds = this.totalLeftMilliseconds-1000;
                this.totalOverdueMilliseconds = this.totalLeftMilliseconds + 1000;
                this.within = true;
                this.outside = false;
            }
            
            if(this.totalLeftMilliseconds >= 1000){
                this.timer = this.msToTime(this.totalLeftMilliseconds);
                this.timer = this.timer + 'left';
                this.totalLeftMilliseconds = this.totalLeftMilliseconds - 1000;
                this.within = true;
                this.outside = false;
            }else if(this.totalOverdueMilliseconds > 1000){
                this.timer = this.msToTime(this.totalOverdueMilliseconds);
                this.timer = this.timer + 'overdue';
                this.totalOverdueMilliseconds = this.totalOverdueMilliseconds  + 1000;
                this.outside = true;
                this.within = false;

            } 
            if(this.totalOverdueMilliseconds < 1000 && this.totalOverdueMilliseconds > 0){
                this.totalOverdueMilliseconds = this.totalOverdueMilliseconds + 1000;
            }
            
        }, 1000);
    }
    @wire(getDataOnLoadSLA, {caseId: '$recordId',caseStageSLA1:'$caseStageSLA1'}) 
    wiredData1(result){
        console.log('entered');
        this.wiredData1 = result;
        if(result.data){
            console.log('entered?', result.data);
            var data = result.data;
           
            if( data.leftTotalSec && data.leftTotalSec > 0){
                this.totalLeftMilliseconds1 = data.leftTotalSec;
            }else if(data.overdueTotalSec && data.overdueTotalSec > 0){
                this.totalOverdueMilliseconds1 = data.overdueTotalSec;
            }
            
            clearInterval(this.timerId1);
            if(data.businessHourWorking){
                this.start1();
            }else{
                if(this.totalLeftMilliseconds1 >= 1000){
                    this.slaTimer = this.msToTime(this.totalLeftMilliseconds1);
                    this.slaTimer = this.slaTimer + 'left';
                    this.stageWithin = true;
                    this.stageOutside = false; 
                }else if(this.totalOverdueMilliseconds1 >= 1000){
                    this.slaTimer = this.msToTime(this.totalOverdueMilliseconds1);
                    this.slaTimer = this.slaTimer + 'overdue';
                    this.stageOutside = true;  
                    this.stageWithin = false;
                } 
            }
        }
        if(result.error){
            console.log(result.error);
        }
    }
    start1() {
        this.timerId1 = setInterval(()=> {
            if(this.totalLeftMilliseconds1 < 1000 && this.totalLeftMilliseconds1 > 0){
                this.slaTimer =  '0 sec left';
                this.totalLeftMilliseconds1 = this.totalLeftMilliseconds1-1000;
                this.totalOverdueMilliseconds1 = this.totalLeftMilliseconds1 + 1000;
                this.stageWithin = true;
                this.stageOutside = false; 
            }
            
            if(this.totalLeftMilliseconds1 >= 1000){
                this.slaTimer = this.msToTime(this.totalLeftMilliseconds1);
                this.slaTimer = this.slaTimer + 'left';
                this.totalLeftMilliseconds1 = this.totalLeftMilliseconds1 - 1000;
                this.stageWithin = true;
                this.stageOutside = false; 
            }else if(this.totalOverdueMilliseconds1 > 1000){
                this.slaTimer = this.msToTime(this.totalOverdueMilliseconds1);
                this.slaTimer = this.slaTimer + 'overdue';
                this.totalOverdueMilliseconds1 = this.totalOverdueMilliseconds1  + 1000;
                this.stageOutside = true;
                this.stageWithin = false;
            } 
            if(this.totalOverdueMilliseconds1 < 1000 && this.totalOverdueMilliseconds1 > 0){
                this.totalOverdueMilliseconds1 = this.totalOverdueMilliseconds1 + 1000;
            }
            
        }, 1000);
    }
    connectedCallback(){
        console.log('in connected callback');
        setTimeout(()=>{
            console.log('refresh apex invokinng');
            refreshApex(this.wiredData);
            console.log('refresh apex done');
        }, 1000);
        //registerListener("refreshpagepubsub", this.handlePublishedMessage, this);
    }
    
    disconnectedCallback(){
        console.log('in disconnected callback');
        clearInterval(this.timerId1);
    }
    msToTime(s) {
        var ms = s % 1000;      
        s = (s - ms) / 1000;
        var secs = s % 60;

        s = (s - secs) / 60;
        var mins = s % 60;

       
        var hrs = (s - mins) / 60;

       
        var timer = '';
        
        if(hrs && hrs>0){
            timer = timer + hrs +' hr ';
        }
        if(mins && mins>0){
            timer = timer + mins +' min ';
        }
        if(secs && secs>0){
            timer = timer + secs +' sec ';
        }
        return timer;
      }
}