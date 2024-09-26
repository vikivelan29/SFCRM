import getDataForDatatable from '@salesforce/apex/ABHI_OmniDocViewController.callOmiDocSearchRequest';
import asfRecordInsert from '@salesforce/apex/ABHI_OmniDocViewController.createASFIntegrationRecord';
import getColumns from '@salesforce/apex/ABHI_OmniDocViewController.getColumnsForDataTable';
import cioPlatfromEventPublish from '@salesforce/apex/ABHI_OmniDocViewController.publishCaseIntegrationOutbound';
import omniDocUrl from '@salesforce/label/c.ABHI_OmniDocURL';
import ACCOUNT_EMAIL from '@salesforce/schema/Asset.Account.PersonEmail';
import ACCOUNT_ID from '@salesforce/schema/Asset.AccountId';
import ASSETID from '@salesforce/schema/Asset.Id';
import ASSET_NAME from '@salesforce/schema/Asset.Name';
import PLAN_NAME from '@salesforce/schema/Asset.Plan_Name__c';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { RefreshEvent } from 'lightning/refresh';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { LightningElement, api, wire } from 'lwc';

const ASSET_FIELDS = [ASSETID, ASSET_NAME, ACCOUNT_ID, PLAN_NAME, ACCOUNT_EMAIL];

export default class ABHI_OmniDocView extends LightningElement {
    @api recordId;
    boolLoad = true;
    showAwaitDoc;
    showEmailComposer;
    policyNumber;
    accountEmail;
    accountId;
    planName;
    currentRow;
    emailComposerWrapRecord;
    customLabel = {omniDocUrl};
    columns = [];
    data = [];
    objASFRecord  = new Map();
    objCurrentASFRec;
    wireData;
    noRecordsAvailable;
    boolShowNoRec;
    objAssetRecord;// = {'sobjectType': 'Asset', 'sobjectFields': 'Account.PersonEmail'};

    @wire(getRecord, { recordId: "$recordId", fields: ASSET_FIELDS })
    async assetRecord({ error, data }) {
        if (error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            }else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            this.showToast("Error loading omidoc wire",message,"error");
            this.boolLoad = false;
        }else if (data) {
            this.wireData = data;
            this.policyNumber = getFieldValue(data, ASSET_NAME);
            this.accountEmail = getFieldValue(data, ACCOUNT_EMAIL);
            this.accountId = getFieldValue(data, ACCOUNT_ID);
            this.planName = getFieldValue(data, PLAN_NAME);
            await this.handleDynamicColumnNames();
            await this.dataForDataTable();
            this.boolLoad = false;
        }
    }

    async handleDynamicColumnNames() {
        return new Promise(async (resolve, reject) =>{
            await getColumns({strParentConfigName: 'ABHI_OmniDocView'}).then(result => {
                if(result){
                    console.log('columns----> ', result);
                    this.columns = result;
                    resolve(result);
                }
            }).catch(error => {
                let message = "Unknown error";
                if (Array.isArray(error.body)) {
                    message = error.body.map((e) => e.message).join(", ");
                }else if (typeof error.body.message === "string") {
                    message = error.body.message;
                }
                this.showToast("Error loading datatable columns",message,"error");
                reject(error);
            });
        });
    }

    async dataForDataTable(){
        return new Promise(async (resolve, reject) =>{
            await getDataForDatatable({strAssetId: this.recordId, strPolicyNo: this.policyNumber}).then((response)=>{
                if(response && response.SearchResponse){
                    for (let i = 0; i < response.SearchResponse.length; i++) {
                        response.SearchResponse[i].policyNumber = this.policyNumber;
                        response.SearchResponse[i].rowUniqueId = Math.random().toString(16).slice(2,13);
                        if(response.SearchResponse[i].Error){
                            if(Array.isArray(response.SearchResponse[i].Error)){
                                for(let j = 0; j < response.SearchResponse[i].Error.length; j++){
                                    if(response.SearchResponse[i].Error[j].Description != 'SUCCESS'){
                                        this.boolShowNoRec = true;
                                        this.noRecordsAvailable = response.SearchResponse[i].Error[j].Description;
                                    }
                                }
                            }
                        }
                    }
                    this.data = response.SearchResponse;
                    resolve(response);
                }
            }).catch(error => {
                let message = "Unknown error";
                if (Array.isArray(error.body)) {
                    message = error.body.map((e) => e.message).join(", ");
                }else if (typeof error.body.message === "string") {
                    message = error.body.message;
                }
                this.showToast("Error loading omidoc",message,"error");
                reject(error);
            });
        });
    }

    handleRowAction(event) {
        console.log('row: ', event.detail.row);
        this.currentRow = event.detail.row;
        switch (event.detail.action.name) {
            case 'docPrev':
                window.open(this.customLabel.omniDocUrl + '&Docid=' + event.detail.row.OmniDocIndex + '&userdbid=' + event.detail.row.VID, '_blank');
                break;
            case 'cmpEmail':
                if(this.objASFRecord.has(event.detail.row.rowUniqueId)){
                    this.objCurrentASFRec = this.objASFRecord.get(event.detail.row.rowUniqueId)
                    console.log('currAsfId::',this.objCurrentASFRec);
                    this.showAwaitDoc = true;
                }else{
                    asfRecordInsert({strAssetId: this.recordId, mapRow: event.detail.row}).then((response)=>{
                        if(response){
                            this.objASFRecord.set(event.detail.row.rowUniqueId, response);
                            this.objCurrentASFRec = response;
                            cioPlatfromEventPublish({strAssetId: this.recordId, mapRow: event.detail.row, strASFRecordId: response.Id}).then((response)=>{
                                if(response){
                                    this.showAwaitDoc = true;
                                }
                            }).catch(error => {
                                let message = "Unknown error";
                                if (Array.isArray(error.body)) {
                                    message = error.body.Map((e) => e.message).join(", ");
                                }else if (typeof error.body.message === "string") {
                                    message = error.body.message;
                                }
                                this.showToast("Error loading omidoc",message,"error");
                            });
                        }
                    }).catch(error => {
                        let message = "Unknown error";
                        if (Array.isArray(error.body)) {
                            message = error.body.Map((e) => e.message).join(", ");
                        }else if (typeof error.body.message === "string") {
                            message = error.body.message;
                        }
                        this.showToast("Error loading omidoc",message,"error");
                    });
                }
                break;
            default:
        }
    }

    createASFIntRecord(event){
        return new promise(async (resolve, reject) =>{
            try{
                var result = await asfRecordInsert({strAssetId: this.recordId});
                resolve(result);
            }catch(error){
                console.log('$$$',error);
                reject(error);
            }
        });
    }

    handleCustomEvent(event){
        this.emailComposerWrapRecord = event.detail.response;
        this.showAwaitDoc = false;
        this.boolLoad = false;
        this.showEmailComposer = true;
        this.objASFRecord.delete(event.detail.row.rowUniqueId);
        this.showToast("Success!","Email sent successfully!","success");
        this.dispatchEvent(new RefreshEvent());
    }

    handleAwaitScreenFailure(event){
        this.showAwaitDoc = false;
        this.boolLoad = false;
        this.objASFRecord.delete(event.detail.row.rowUniqueId);
        this.showToast("Error",event.detail.message,"error");
        this.dispatchEvent(new RefreshEvent());
    }

    handleAwaitScreenTimeout(event){
        this.showAwaitDoc = false;
        this.boolLoad = false;
        this.showEmailComposer = false;
        this.showToast("Error",event.detail,"error");
        this.dispatchEvent(new RefreshEvent());
    }

    handleCloseEmail(event){
        this.showAwaitDoc = false;
        this.showEmailComposer = false;
    }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }

}
