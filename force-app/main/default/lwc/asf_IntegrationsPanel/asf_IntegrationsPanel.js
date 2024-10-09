/* eslint-disable handle-callback-err */
/* eslint-disable no-unused-vars */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable eqeqeq */
/* eslint-disable no-empty */
import { LightningElement, api, wire } from 'lwc';
import { reduceErrors } from 'c/asf_ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllIntegrations from "@salesforce/apex/ASF_IntegrationsController.getAllIntegrations";
import getAllCaseIntegrations from '@salesforce/apex/ASF_IntegrationsController.getAllCaseIntegrations';
import runIntegration from "@salesforce/apex/ASF_IntegrationsController.runIntegration";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import C3_FIELD from "@salesforce/schema/Case.CCC_External_Id__c";
import CASE_ID from "@salesforce/schema/Case.Id";
import CASE_STAGE from '@salesforce/schema/Case.Stage__c';
import {RefreshEvent } from 'lightning/refresh'
import { refreshApex } from '@salesforce/apex';



// Virendra - Added Refresh Event to fire when Click on Refresh Button on UI.

import { fireEventNoPageRef, registerListener } from 'c/asf_pubsub';

/**
 * Integrations Panel is one Component to be included above the Regular Case 
 * Standard / Custom Pages. It shows Dynamic Buttons for running integrations
 * And also Fires event after prepopulating Values on Case / Case Extension objects
 */
export default class Asf_IntegrationsPanel extends LightningElement {

    // Case Id passed by default in the record page
    @api recordId;
    refreshHandlerID;

    caseC3ExtId;
    caseStageName;
    allIntegrations;
    caseRecord;
    allIntExtIds;
    allActions;
    isModalOpen;
    selectedAction;
    _wiredCaseIntegrations;
    componentConstructor;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [C3_FIELD, CASE_STAGE, CASE_ID]
    })
    wiredCaseRecord({ error, data }) {
        if (data) {
          this.caseC3ExtId = getFieldValue(data, C3_FIELD);
          this.caseStageName = getFieldValue(data, CASE_STAGE);
          let tempCaseRec = {};
          Object.keys(data.fields).forEach((fld) =>{
            tempCaseRec[fld] = data.fields[fld].value;
          });
          this.caseRecord = tempCaseRec;
        } else if (error) {
          
        }
      }

    @wire(getAllIntegrations, {c3ExtId: "$caseC3ExtId", stageName:"$caseStageName"})
    wiredIntegrationsList({ error, data }) {
        if (data) {
          this.allIntegrations = data;
          debugger;
          this.allIntExtIds = this.allIntegrations.map((intRec) => intRec.External_Id__c);
        } else if (error) {
          
        }
    }

    @wire(getAllCaseIntegrations, {caseId: "$recordId", intExtIds:"$allIntExtIds"})
    wiredCaseIntegratonsList(result){
      this._wiredCaseIntegrations = result;
      if (result.data) {
          
          let finalActionList = [];
          this.allIntegrations.forEach((int) =>{
            let caseInt = result.data.find((el) => el.Integration_Ext_Id__c == int.External_Id__c);
            // If Case Integration Found
            if(caseInt){
              finalActionList.push({
                label:int.Display_Name__c,
                status:caseInt.Status__c,
                intExtId:int.External_Id__c,
                type:int.Type__c,
                caseIntId:caseInt.Id,
                id:int.Id,
                icon:caseInt.Status__c == 'Pending'?'utility:expired':(caseInt.Status__c == 'Success'?'utility:success':'utility:error'),
                class:caseInt.Status__c == 'Pending'?'pendingBtn':(caseInt.Status__c == 'Success'?'successBtn':'errorBtn'),
                isSuccess:caseInt.Status__c == 'Success',
                isFailure:caseInt.Status__c == 'Failure',
                isPending:caseInt.Status__c == 'Pending',
                uiComponent:int.UI_Component__c
              })
            }
            else{
              finalActionList.push({
                label:int.Display_Name__c,
                status:'Not Started',
                intExtId:int.External_Id__c,
                id:int.Id,
                type:int.Type__c,
                icon:'utility:ban',
                class:'notStartedBtn',
                isNotStarted:true,
                uiComponent:int.UI_Component__c
              })
            }
          })

          let notRunPrePop = finalActionList.find((el) => el.type == 'Pre Populate' && el.isNotStarted);
          if(notRunPrePop){
            this.runPrepopulateIntegrations();
          }
          this.allActions = finalActionList;

      } else if (result.error) {
      
      }
    }

    refresh(){
      refreshApex(this._wiredCaseIntegrations);

      // VIRENDRA - Added fixes for the Refreshing the page when 
      let payload = {'source':'intPanel', 'recordId':this.recordId};
      fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload);  
    }

    openModal() {
      // to open modal set isModalOpen value as true
      this.isModalOpen = true;
    }
    closeModal() {
      // to close modal set isModalOpen value as false
      this.isModalOpen = false;
      this.selectedAction = undefined;
    }

    get areActionsPresent(){
      return (this.allIntegrations && this.allIntegrations.length);
    }
    get isUIActionSelected(){
      return this.selectedAction && this.selectedAction.type == 'UI Action';
    }
    actionSelected(event){
      let intId = event.target.dataset.id;
      this.selectedAction = this.allActions.find((el) => el.id == intId);
      this.loadDynamicUIAction();
      this.openModal();
    }
    async loadDynamicUIAction(){
      if(this.isUIActionSelected && this.selectedAction.uiComponent){
        const { default: ctor } = await import("c/" + this.selectedAction.uiComponent)
        .catch((err) => console.log("loadDynamicUIAction Error importing component", JSON.stringify(err)));
        this.componentConstructor = ctor;
      }else{
        //this.showMessage('error', 'Error while running Integration', 'No screen specified for this action, contact system administrator');
      }
    }

    sendRefreshEvent(){
        // Since the Case Details have been modified, fire a Refresh Event
        // For any Subscriber listening to it, so the Case Details are refreshed
        this.dispatchEvent(new RefreshEvent());                 
    }

    //utility method
    showMessage(variant, title, message) {
      let errMsg = reduceErrors(message);
      const event = new ShowToastEvent({
          variant: variant,
          title: title,
          message: Array.isArray(errMsg) ? errMsg[0] : errMsg
      });
      this.dispatchEvent(event);
  }

    submit(){
      // Find Int Record
      let selectedInt = this.allIntegrations.find((el) => el.Id == this.selectedAction.id);
      debugger;
      
      if(selectedInt){
        runIntegration({integ:selectedInt, caseRec:this.caseRecord})
        .then((result) =>{
          if(result.status != 'Success'){
            this.showMessage('error', 'Error while running Integration', result.response);
          }
          
          console.log("SUCCESSFUL RUN - INT PANEL")
          this.sendRefreshEvent();
          refreshApex(this._wiredCaseIntegrations);
          this.closeModal();
        })
        .catch((error) =>{
            console.log(error);
            this.closeModal();
        })
      }

    }

    runPrepopulateIntegrations(){
      // Run Pre Populate Type of Integrations Here
      let allPrePopPromises = [];
      this.allIntegrations.forEach((int) =>{
          if(int.Type__c == 'Pre Populate'){
            allPrePopPromises.push(runIntegration({integ:int, caseRec:this.caseRecord}));
          }
      })
      Promise.all(allPrePopPromises)
      .then((result) =>{
          console.log("SUCCESSFUL RUN - INT PANEL")
          //setTimeout(this.respondToParent, 500)
          this.sendRefreshEvent();
          refreshApex(this._wiredCaseIntegrations);
      })
      .catch((error) =>{
          console.log(error);
      })
    }
   
}