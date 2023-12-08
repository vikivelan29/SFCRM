import { LightningElement, api, wire } from 'lwc';
import getCasePath1 from "@salesforce/apex/ASF_CasePathController.getCasePath1";
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/asf_pubsub';
import subscribeBrowserEvent from '@salesforce/label/c.ASF_CaseBrowserSubscriber';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
const CASE_FIELDS = [CASE_STAGE];

export default class asf_CasePath1 extends NavigationMixin(LightningElement) {
    @api recordId;
    stages = [];
    hoverStyle = 'display:none;';
    hoverStageName = '';

    //Start: To fix Rejection refresh issue
    @wire(getRecord, { recordId: '$recordId', fields: "$fields" })
    wiredCaseObj({ error, data }) {
        if (data) {
            this.getCasePathInfo();
        }
    }
    get fields() {
        return CASE_FIELDS;
    }
    //End: To fix Rejection refresh issue

    connectedCallback() {
        registerListener("refreshpagepubsub", this.handlePublishedMessage, this);
        this.getCasePathInfo();

    }
    handleScrollRight(e) {
        console.log('coming here', this.template.querySelector('.slds-path__nav'))

        this.template.querySelector('.slds-path__nav').scrollLeft += 50;
    }

    handleScrollLeft(e) {
        console.log('coming here', this.template.querySelector('.slds-path__nav'))

        this.template.querySelector('.slds-path__nav').scrollLeft -= 50;
    }

    handleMouseOver(e) {
        let rect = e.target.getBoundingClientRect();
        console.log(JSON.stringify(rect))
        this.hoverStageName = e.currentTarget.dataset.name;
        this.hoverStyle = `left:${rect.x}px;top:${rect.y}px;position:fixed;margin-top:40px;`
        console.log(this.hoverStyle);
    }

    handleMouseLeave(e) {
        this.hoverStyle = 'display:none;';
    }



    disconnectedCallback() {
        unregisterAllListeners(this);
    }
    @wire(CurrentPageReference) pageRef;

    handlePublishedMessage(payload) {
        console.log('handlePublishedMessage of casepath');
        if (subscribeBrowserEvent.trim().toUpperCase() == "TRUE") {
            if (payload.source != 'casepath' && this.recordId == payload.recordId) {
                this.getCasePathInfo();
            }
        }

    }
    constructor() {
        super();
        document.addEventListener('refreshCurrentPg', this.handlePublishedEvent.bind(this));
        document.addEventListener('refreshCurrentPgForReopen', this.handlePublishedEventFromReopen.bind(this));
    }
    handlePublishedEventFromReopen(event){
        event.preventDefault();
        if (this.recordId == event.detail) {
            this.getCasePathInfo();
        }

    }
    handlePublishedEvent(event) {
        event.preventDefault();
        if (subscribeBrowserEvent.trim().toUpperCase() == "TRUE") {
            if (this.recordId == event.detail) {
                this.getCasePathInfo();
            }
        }

    }
    getCasePathInfo() {
        getCasePath1({ recordId: this.recordId })
            .then(result => {
                console.log(result)
                this.stages = result;
            })
            .catch(error => {
                console.log(error);
            });
    }
}