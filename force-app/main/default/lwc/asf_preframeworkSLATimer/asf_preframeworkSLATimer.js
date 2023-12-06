import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getDataOnLoadSLA from '@salesforce/apex/ASF_PreFrameworkSLA.getDataOnLoad';
import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
const CASE_FIELDS = [CASE_STAGE];


export default class Asf_preframeworkSLATimer extends LightningElement {
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

    @wire(getRecord, { recordId: '$recordId', fields: "$fields" })
    wiredCaseObj({ error, data }) {
        if (data) {
            this.fetchSLAInfo();
        }
    }
    get fields() {
        return CASE_FIELDS;
    }

    fetchSLAInfo() {
        getDataOnLoadSLA({ caseId: this.recordId })
            .then(result => {
                if (result) {
                    var data = result;
                    if (data.leftTotalSec && data.leftTotalSec > 0) {
                        this.totalLeftMilliseconds1 = data.leftTotalSec;
                    } else if (data.overdueTotalSec && data.overdueTotalSec > 0) {
                        this.totalOverdueMilliseconds1 = data.overdueTotalSec;
                    }

                    clearInterval(this.timerId1);
                    if (data.businessHourWorking) {
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
            })
            .catch(error => {
                console.log(error);
            });
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
    disconnectedCallback() {
        clearInterval(this.timerId1);
    }
    msToTime(s) {
        var ms = s % 1000;
        s = (s - ms) / 1000;
        var secs = s % 60;

        s = (s - secs) / 60;
        var mins = s % 60;

        // s= (s - mins) / 60;
        //var hrs = s % 24;
        var hrs = (s - mins) / 60;

        //var days = (s-hrs) / 24;

        var timer = '';
        //if(days && days>0){
        //    timer = days +' days ';
        // }

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
}