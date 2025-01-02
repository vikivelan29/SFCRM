import { LightningElement, track, api, wire } from 'lwc';
import getPolicyExternalData from "@salesforce/apex/ABHI_KavachPolicies.getPolicyExternalData";

import LightningModal from 'lightning/modal';
import getPolicyData from "@salesforce/apex/ABHI_KavachPolicies.getPolicyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import buttonInfo from '@salesforce/label/c.ABHI_Kavach_Policy_Info';
import policyValidation from '@salesforce/label/c.ABHI_PolicyRequired_ErrMsg1';
import policyCreationStatus from '@salesforce/label/c.ABHI_Kavach_Policy_Status';
import policyCreationStatusMessage from '@salesforce/label/c.ABHI_Kavach_Policy_RequestMessage';


import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue,notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

export default class Abhi_kavach_Policies extends LightningModal {
   
    displayTable = false;
    displayError = false;
    isLoading = false;
    loaded = false;
    disabled = false;
    disabledSearch = true;
    isModalOpen = false;
    //data;
    @track data = [];
    selectedOption;
    selectedSystem = 'Jarvis';
    targetSysOptions;
    columns;
    errorMessage;
    modalBody;
   
    searchPolicy;

    label = {
        errorMessage,
        pageSize,
        buttonInfo,
        policyValidation,
        policyCreationStatus,
        policyCreationStatusMessage
    };
    
    connectedCallback() {
        console.log('***rec'+this.recordId);
        // get columns
        getColumns({configName:'ABHI_Kavach_Policy'})
        .then(result => {
                console.log('**rec2>'+JSON.stringify(result));
                this.columns = [{
                        label: 'Policy No',
                        fieldName: 'policyNo',
                        type: 'url',
                        typeAttributes: {label: { fieldName: 'name' }, 
                        target: '_blank'},
                        sortable: true
                    },
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
            })
            .catch(error => {
                this.showNotification('Error','Error fetching data.','Error');
            });

            getColumns({configName:'ABHI_Kavach_Policy_Systems'})
            .then(result => {
                    console.log('**rec2>'+JSON.stringify(result));
                    this.targetSysOptions = [
                        ...result.map(col => ({
                            label: col.MasterLabel,
                            value: col.MasterLabel
                        })),
                    ];
                })
                .catch(error => {
                    this.showNotification('Error','Error fetching data.','Error');
                });    
    }

    fetchExistingData() {
        this.displayError = false;
        this.isLoading = true;
        this.data=[];
        this.displayTable = false;
        this.searchPolicy = this.template.querySelector('lightning-input[data-name="policy"]').value;
        console.log('Result1 ==> ', this.searchPolicy);
        if(this.searchPolicy) {
            //this.disabled = true;
            this.isLoading = true;
            getPolicyData({policyNo: this.searchPolicy}).then(result=>{
                this.data = result;
                console.log('Result2 ==> ', this.searchPolicy);
                if(this.data.length > 0 && !this.data[0].hasOwnProperty('status')) {
                    this.displayTable = true;
                    console.log('Result1 ==> ', this.data);
                    
                }
                else if(this.data.length > 0 && this.data[0].status == 'Pending') {
                    this.disabledSearch = false;
                    this.isModalOpen = true;
                    this.modalBody = this.data[0].message+'\n'+policyCreationStatusMessage;
                    
                }
                else if(this.data.length > 0 && this.data[0].status == 'Failure') {
                    this.disabledSearch = false;
                    //Show popup
                    this.isModalOpen = true;
                    this.modalBody = this.data[0].message+'\n'+policyCreationStatusMessage;
                    
                }
                else{
                    this.disabledSearch = false;
                    this.showNotification("", buttonInfo, 'info');
                }
                this.isLoading = false;
                
            }).catch(error=>{
                console.log('error ==> ', error);
                this.showNotification("Error", this.label.errorMessage, 'error');
                this.isLoading = false;
                this.loaded = true;
                this.disabled = false;
            })
        }
        else{
            this.showNotification("", this.label.policyValidation, 'error');
            this.isLoading = false;
        }    

    }
    
    getPolicyDetails(){
        this.isLoading = true;
        console.log('Result1 @@ ==> '+ this.searchPolicy);
        getPolicyExternalData({policyNo: this.searchPolicy, selectedSystem : this.selectedSystem}).then(result=>{


            setTimeout(() => {
                this.showNotification("", policyCreationStatus, 'info');
                this.isLoading = false;
                this.disabledSearch = true;
              }, 3000);
            
            
           
       }).catch(error=>{
           console.log('error ==> ', error);
           this.showNotification("Error", error.body.message, 'error');
           this.isLoading = false;
           this.loaded = true;
           this.disabled = false;
       })
    }
   
    handleChange(event) {
        this.disabledSearch = true;
    }
    handleChangeTargetSys(event) {
        this.selectedSystem = event.detail.value;
    }
    handleSearch(event){
        this.selectedSystem = event.detail.value;
    }
    get options() {
        return [
            { label: 'Policy No', value: 'PolicyNo' },
            { label: 'Master Policy No', value: 'MasterPolicyNo' },

        ];
    }
    
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
    this.dispatchEvent(evt);
    }

    closeModal() {
        this.isModalOpen = false;
    }
}