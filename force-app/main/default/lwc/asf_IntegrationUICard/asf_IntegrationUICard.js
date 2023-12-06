/* eslint-disable no-await-in-loop */
/* eslint-disable no-empty-function */
/* eslint-disable no-alert */
/* eslint-disable handle-callback-err */
/* eslint-disable no-unused-vars */
/* eslint-disable eqeqeq */
/* eslint-disable no-empty */
import { LightningElement, api, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import getAllUIIntegrations from "@salesforce/apex/ASF_IntegrationsController.getAllUIIntegrations";
import getAllCaseIntegrations from '@salesforce/apex/ASF_IntegrationsController.getAllCaseIntegrations';
import runIntegration from "@salesforce/apex/ASF_IntegrationsController.runIntegration";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import C3_FIELD from "@salesforce/schema/Case.CCC_External_Id__c";
import CASE_ID from "@salesforce/schema/Case.Id";
import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
import { RefreshEvent } from 'lightning/refresh'
import { refreshApex } from '@salesforce/apex';

export default class Asf_IntegrationUICard extends LightningElement {

    // Case Id passed by default in the record page
    @api recordId;
    refreshHandlerID;

    caseC3ExtId;
    caseStageName;
    allIntegrations;
    caseRecord;
    allIntExtIds;
    allActions = [];
    isModalOpen;
    selectedAction;
    _wiredCaseIntegrations;
    uiComponents

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [C3_FIELD, CASE_STAGE, CASE_ID]
    })
    wiredCaseRecord({ error, data }) {
        if (data) {
            this.caseC3ExtId = getFieldValue(data, C3_FIELD);
            this.caseStageName = getFieldValue(data, CASE_STAGE);
            let tempCaseRec = {};
            Object.keys(data.fields).forEach((fld) => {
                tempCaseRec[fld] = data.fields[fld].value;
            });
            this.caseRecord = tempCaseRec;
        } else if (error) {

        }
    }

    @wire(getAllUIIntegrations, { c3ExtId: "$caseC3ExtId", stageName: "$caseStageName" })
    wiredIntegrationsList({ error, data }) {
        if (data) {
            this.allIntegrations = data;
            this.allIntExtIds = this.allIntegrations.map((intRec) => intRec.External_Id__c);
        } else if (error) {

        }
    }

    refresh() {
        refreshApex(this._wiredCaseIntegrations);
    }

    async buildAllCards(caseIntegrations) {

        let finalActionArray = [];
        for (const int of this.allIntegrations) {

            let caseInt = caseIntegrations.find((el) => el.Integration_Ext_Id__c == int.External_Id__c);
            const { default: ctor } = await import(int.UI_Component__c);
            if (caseInt) {
                finalActionArray.push({
                    label: int.Display_Name__c,
                    status: caseInt.Status__c,
                    intExtId: int.External_Id__c,
                    type: int.Type__c,
                    caseIntId: caseInt.Id,
                    lastModified: caseInt.LastModifiedDate,
                    id: int.Id,
                    icon: caseInt.Status__c == 'Pending' ? 'utility:expired' : (caseInt.Status__c == 'Success' ? 'utility:success' : 'utility:error'),
                    class: caseInt.Status__c == 'Pending' ? 'pendingBtn' : (caseInt.Status__c == 'Success' ? 'successBtn' : 'errorBtn'),
                    isSuccess: caseInt.Status__c == 'Success',
                    isFailure: caseInt.Status__c == 'Failure',
                    isPending: caseInt.Status__c == 'Pending',
                    uiComponent: ctor,
                    uiComponentDisplay: false
                })
            }
            else {
                finalActionArray.push({
                    label: int.Display_Name__c,
                    status: 'Not Started',
                    intExtId: int.External_Id__c,
                    id: int.Id,
                    type: int.Type__c,
                    icon: 'utility:ban',
                    class: 'notStartedBtn',
                    isNotStarted: true,
                    uiComponent: ctor,
                    uiComponentDisplay: false
                });
            }
        }

        this.allActions = finalActionArray;
        let notRunInts = this.allActions.find((el) => el.isNotStarted);
        if (notRunInts) {

            this.runInitialIntegrations();
        }
    }

    @wire(getAllCaseIntegrations, { caseId: "$recordId", intExtIds: "$allIntExtIds" })
    wiredCaseIntegratonsList(result) {
        this._wiredCaseIntegrations = result;
        if (result.data) {

            this.buildAllCards(result.data);

        } else if (result.error) {

        }
    }

    async handleConfirmClick(event) {
        let intId = event.target.dataset.id;
        let selectedInt = this.allIntegrations.find((el) => el.Id == intId);
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to run ? This will override any previous results',
            variant: 'header',
            label: 'Confirm',
            theme: 'warning'
            // setting theme would have no effect
        });
        if (result) {
            this.runAction(selectedInt)
        }
        //Confirm has been closed
        //result is true if OK was clicked
        //and false if cancel was clicked
    }

    handleTogglePanel(event) {
        let index = event.target.dataset.index;
        this.allActions[index].uiComponentDisplay = !this.allActions[index].uiComponentDisplay;
        this.allActions = [...this.allActions];
    }

    runAction(selectedInt) {

        runIntegration({ integ: selectedInt, caseRec: this.caseRecord })
            .then((result) => {
                console.log("SUCCESSFUL RUN - INT UI CARD")
                this.sendRefreshEvent();
                refreshApex(this._wiredCaseIntegrations);
            })
            .catch((error) => {
                console.log(error);
            })
    }

    get arePanelsPresent() {
        return (this.allIntegrations && this.allIntegrations.length);
    }

    sendRefreshEvent() {
        // Since the Case Details have been modified, fire a Refresh Event
        // For any Subscriber listening to it, so the Case Details are refreshed
        this.dispatchEvent(new RefreshEvent());
    }

    runInitialIntegrations() {
        // Run Pre Populate Type of Integrations Here
        let allPrePopPromises = [];
        this.allIntegrations.forEach((int) => {
            if (int.Auto_Run_on_Load__c) {
                allPrePopPromises.push(runIntegration({ integ: int, caseRec: this.caseRecord }));
            }
        })
        Promise.all(allPrePopPromises)
            .then((result) => {
                console.log("SUCCESSFUL RUN - INT UI CARD")
                this.sendRefreshEvent();
                refreshApex(this._wiredCaseIntegrations);
            })
            .catch((error) => {
                console.log(error);
            })
    }

}