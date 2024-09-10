import { LightningElement, wire, track, api } from 'lwc';
//import {  getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getDataOnLoad from '@salesforce/apex/ASF_ClosedMilestoneTimeController.getDataOnLoad';
//import getDataOnLoadSLA from '@salesforce/apex/ASF_StageBasedMilestoneTimerController.getDataOnLoad';
// import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
// import CASE_CLOSE_SLA from '@salesforce/schema/Case.Overall_Case_Closure_SLA__c';
// import CASE_STAGE_SLA_1 from '@salesforce/schema/Case.Stage_SLA_1__c';
// import fetchCase from '@salesforce/schema/Case.CaseNumber';
import { registerListener, unregisterAllListeners } from 'c/asf_pubsub';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
//const fields = [CASE_STAGE,CASE_CLOSE_SLA,CASE_STAGE_SLA_1,fetchCase];

export default class ASF_caseClosureandMilestonePath extends NavigationMixin(LightningElement) {
    @api recordId;
    timer;
    timerId;
    slaTimer;
    totalLeftMilliseconds;
    totalOverdueMilliseconds;
    timerId1;
    totalLeftMilliseconds1;
    totalOverdueMilliseconds1;
    within;
    outside;
    stageWithin;
    stageOutside;
    showAdditionalSLA = false;
    expandCollapseLbl = 'Expand';

    //Overall
    overallWrap;
    overallStyle;
    overallTAT;
    
    //SLA1
    sla1Wrap;
    sla1Style;
    sla1TAT;

    //SLA2
    sla2Wrap;
    sla2Style;
    sla2TAT;

    //SLA3
    sla3Wrap;
    sla3Style;
    sla3TAT;

    iconName = "utility:expand_all";
    
    

    caseObj;
    @api displayType;
    @api primarySLA;
    get showTimer() {
        //default display type is Timer
        return this.displayType == undefined || this.displayType == 'Timer';
    }
    get sla1Prop(){
        return {'label':'Level 1 Stage SLA','slaValue':this.caseObj?this.caseObj.Stage_SLA_1__c:null,'slaStyle':this.sla1Style};
    }
    get sla2Prop(){
        return {'label':'Level 2 Stage SLA','slaValue':this.caseObj?this.caseObj.Stage_SLA_2__c:null,'slaStyle':this.sla2Style};
    }
    get sla3Prop(){
        return {'label':'Level 3 Stage SLA','slaValue':this.caseObj?this.caseObj.Stage_SLA_3__c:null,'slaStyle':this.sla3Style};
    }
    get sla1TATProp(){
        return {'label':'Level 1 Turnaround Time(TAT)','slaValue':this.caseObj?this.caseObj.Stage_SLA_1__c:null,'slaTAT':this.sla1TAT};
    }
    get sla2TATProp(){
        return {'label':'Level 2 Turnaround Time(TAT)','slaValue':this.caseObj?this.caseObj.Stage_SLA_2__c:null,'slaTAT':this.sla2TAT};
    }
    get sla3TATProp(){
        return {'label':'Level 3 Turnaround Time(TAT)','slaValue':this.caseObj?this.caseObj.Stage_SLA_3__c:null,'slaTAT':this.sla3TAT};
    }
    get primarySLAProp(){
        if(this.primarySLA == 'sla1'){
            return this.sla1Prop;
        }else if(this.primarySLA == 'sla2'){
            return this.sla2Prop;
        }
        else{
            //nothing specified or sla3 specified
            return this.sla3Prop;
        }
    }
    get primarySLATATProp(){
        if(this.primarySLA == 'sla1'){
            return this.sla1TATProp;
        }else if(this.primarySLA == 'sla2'){
            return this.sla2TATProp;
        }
        else{
            return this.sla3TATProp;
        }
    }
    get secondarySLAProp(){
        if(this.primarySLA == 'sla1'){
            return this.sla2Prop;
        }else if(this.primarySLA == 'sla2'){
            return this.sla1Prop;
        }
        else{
            //nothing specified or sla3 specified
            return this.sla1Prop;
        }
    }
    get tertiarySLAProp(){
        if(this.primarySLA == 'sla1'){
            return this.sla3Prop;
        }else if(this.primarySLA == 'sla2'){
            return this.sla3Prop;
        }
        else{
            //nothing specified or sla3 specified
            return this.sla2Prop;
        }
    }

    get overallTAT_Timer(){
        return this.outside ? 'Outside TAT' : 'Within TAT';
    }
    get stageTAT_Timer(){
        return this.stageOutside ? 'Outside TAT' : 'Within TAT';
    }

    async loadData() {
        let slaMap = await getDataOnLoad({ caseId: this.recordId }).catch(error => { console.log(error) });
        if (slaMap) {
            if (this.showTimer) {
                if (slaMap.overall) {
                    let data = slaMap.overall;
                    if (data.leftTotalSec && data.leftTotalSec > 0) {
                        this.totalLeftMilliseconds = data.leftTotalSec;
                    } else if (data.overdueTotalSec && data.overdueTotalSec > 0) {
                        this.totalOverdueMilliseconds = data.overdueTotalSec;
                    }

                    clearInterval(this.timerId);

                    if (data.businessHourWorking && data.isClosed == false) {
                        this.start();
                    } else {
                        if (this.totalLeftMilliseconds >= 1000) {
                            this.timer = this.msToTime(this.totalLeftMilliseconds);
                            this.timer = this.timer + 'left';
                            this.within = true;
                            this.outside = false;
                        } else if (this.totalOverdueMilliseconds >= 1000) {
                            this.timer = this.msToTime(this.totalOverdueMilliseconds);
                            this.timer = this.timer + 'overdue';
                            this.outside = true;
                            this.within = false;
                        }
                    }
                }
                if (slaMap.sla1) {
                    let data = slaMap.sla1;
                    if (data.leftTotalSec && data.leftTotalSec > 0) {
                        this.totalLeftMilliseconds1 = data.leftTotalSec;
                    } else if (data.overdueTotalSec && data.overdueTotalSec > 0) {
                        this.totalOverdueMilliseconds1 = data.overdueTotalSec;
                    }

                    clearInterval(this.timerId1);
                    if (data.businessHourWorking && data.isClosed == false) {
                        this.start1();
                    } else {
                        if (this.totalLeftMilliseconds1 >= 1000) {
                            this.slaTimer = this.msToTime(this.totalLeftMilliseconds1);
                            this.slaTimer = this.slaTimer + 'left';
                            this.stageWithin = true;
                            this.stageOutside = false;
                        } else if (this.totalOverdueMilliseconds1 >= 1000) {
                            this.slaTimer = this.msToTime(this.totalOverdueMilliseconds1);
                            this.slaTimer = this.slaTimer + 'overdue';
                            this.stageOutside = true;
                            this.stageWithin = false;
                        }
                    }
                }
            }
            else{
                this.caseObj = slaMap.overall.caseObj;
                console.log('caseobj', JSON.stringify(slaMap));
                this.overallWrap = slaMap.overall;
                this.sla1Wrap = slaMap.sla1;
                this.sla2Wrap = slaMap.sla2;
                this.sla3Wrap = slaMap.sla3;
                if(this.overallWrap.isClosed == false){
                    this.startNewTimer();
                }else{
                    this.evaluateSLAs();
                }   
            }
        }
    }

    startNewTimer() {
        this.timerId = setInterval(()=>{this.evaluateSLAs();}, 1000);
    }

    evaluateSLAs(){
        //if(this.overallWrap && this.overallWrap.slaMilliseconds > new Date()){
        if(this.overallWrap && this.overallWrap.isBreached == false){
            this.overallTAT = 'Within TAT';
            this.overallStyle = 'slds-text-body_small';
        }else{
            this.overallTAT = 'Outside TAT';
            this.overallStyle = 'breached-sla slds-text-body_small';
        }

        if(this.sla3Wrap && this.sla3Wrap.isBreached == false){
            this.sla3TAT = 'Within TAT';
            this.sla3Style = 'slds-text-body_small';
        }else{
            this.sla3TAT = 'Outside TAT';
            this.sla3Style = 'breached-sla slds-text-body_small';
        }

        if(this.sla1Wrap && this.sla1Wrap.isBreached == false){
            this.sla1TAT = 'Within TAT';
            this.sla1Style = 'slds-text-body_small';
        }else{
            this.sla1TAT = 'Outside TAT';
            this.sla1Style = 'breached-sla slds-text-body_small';
        }

        if(this.sla2Wrap && this.sla2Wrap.isBreached == false){
            this.sla2TAT = 'Within TAT';
            this.sla2Style = 'slds-text-body_small';
        }else{
            this.sla2TAT = 'Outside TAT';
            this.sla2Style = 'breached-sla slds-text-body_small';
        }
    }
    
    start() {
        this.timerId = setInterval(() => {
            if (this.totalLeftMilliseconds < 1000 && this.totalLeftMilliseconds > 0) {
                this.timer = '0 sec left';
                this.totalLeftMilliseconds = this.totalLeftMilliseconds - 1000;
                this.totalOverdueMilliseconds = this.totalLeftMilliseconds + 1000;
                this.within = true;
                this.outside = false;
            }

            if (this.totalLeftMilliseconds >= 1000) {
                this.timer = this.msToTime(this.totalLeftMilliseconds);
                this.timer = this.timer + 'left';
                this.totalLeftMilliseconds = this.totalLeftMilliseconds - 1000;
                this.within = true;
                this.outside = false;
            } else if (this.totalOverdueMilliseconds > 1000) {
                this.timer = this.msToTime(this.totalOverdueMilliseconds);
                this.timer = this.timer + 'overdue';
                this.totalOverdueMilliseconds = this.totalOverdueMilliseconds + 1000;
                this.outside = true;
                this.within = false;

            }
            if (this.totalOverdueMilliseconds < 1000 && this.totalOverdueMilliseconds > 0) {
                this.totalOverdueMilliseconds = this.totalOverdueMilliseconds + 1000;
            }

        }, 1000);
    }

    start1() {
        this.timerId1 = setInterval(() => {
            if (this.totalLeftMilliseconds1 < 1000 && this.totalLeftMilliseconds1 > 0) {
                this.slaTimer = '0 sec left';
                this.totalLeftMilliseconds1 = this.totalLeftMilliseconds1 - 1000;
                this.totalOverdueMilliseconds1 = this.totalLeftMilliseconds1 + 1000;
                this.stageWithin = true;
                this.stageOutside = false;
            }

            if (this.totalLeftMilliseconds1 >= 1000) {
                this.slaTimer = this.msToTime(this.totalLeftMilliseconds1);
                this.slaTimer = this.slaTimer + 'left';
                this.totalLeftMilliseconds1 = this.totalLeftMilliseconds1 - 1000;
                this.stageWithin = true;
                this.stageOutside = false;
            } else if (this.totalOverdueMilliseconds1 > 1000) {
                this.slaTimer = this.msToTime(this.totalOverdueMilliseconds1);
                this.slaTimer = this.slaTimer + 'overdue';
                this.totalOverdueMilliseconds1 = this.totalOverdueMilliseconds1 + 1000;
                this.stageOutside = true;
                this.stageWithin = false;
            }
            if (this.totalOverdueMilliseconds1 < 1000 && this.totalOverdueMilliseconds1 > 0) {
                this.totalOverdueMilliseconds1 = this.totalOverdueMilliseconds1 + 1000;
            }

        }, 1000);
    }
    connectedCallback() {
        //Currently refreshing through the casePath1 component using refreshView
        registerListener("refreshpagepubsub", this.handlePublishedMessage, this);
        console.log('in SLA connected callback');
        this.loadData();
    }
    @wire(CurrentPageReference) pageRef;

    handlePublishedMessage(payload) {
        console.log('handlePublishedMessage of case SLA');
        if (this.recordId == payload.recordId) {
            this.loadData();
        }
    }
    disconnectedCallback() {
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

        if (hrs && hrs > 0) {
            timer = timer + hrs + ' hr ';
        }
        if (mins && mins > 0) {
            timer = timer + mins + ' min ';
        }
        if (secs && secs > 0) {
            timer = timer + secs + ' sec ';
        }
        return timer;
    }

    openAllPanels(event) {
        this.showAdditionalSLA = !this.showAdditionalSLA;
        this.expandCollapseLbl = this.showAdditionalSLA ? 'Collapse' : 'Expand';
        this.iconName = this.showAdditionalSLA ? 'utility:collapse_all' : 'utility:expand_all';
        //$(aId + ' .panel-collapse:not(".in")').collapse('show');

    }

}