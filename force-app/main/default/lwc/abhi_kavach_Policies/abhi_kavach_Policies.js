import { LightningElement, track, api, wire } from 'lwc';
import getPolicyExternalData from "@salesforce/apex/ABHI_KavachPolicies.getPolicyExternalData";
import getPolicyData from "@salesforce/apex/ABHI_KavachPolicies.getPolicyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import buttonInfo from '@salesforce/label/c.ABHI_Kavach_Policy_Info';
import policyValidation from '@salesforce/label/c.ABHI_PolicyRequired_ErrMsg1';

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

/*import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
import LOB_FIELD from "@salesforce/schema/Account.Business_Unit__c";
const fields = [CLIENT_CODE_FIELD, LOB_FIELD];   */

export default class Abhi_kavach_Policies extends LightningElement {
   
    displayTable = false;
    displayError = false;
    isLoading = false;
    loaded = false;
    disabled = false;
    disabledSearch = true;
    //data;
    @track data = [];
    selectedOption;
    selectedSystem = 'Jarvis';
    targetSysOptions;
    columns;
    errorMessage;
   
    searchPolicy;

    label = {
        errorMessage,
        pageSize,
        buttonInfo,
        policyValidation
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
       /* this.searchMasterPolicy = this.template.querySelector('lightning-input[data-name="masterpolicy"]').value;
        console.log('Result1 ==> ', this.searchMasterPolicy);*/
        if(this.searchPolicy /*|| this.searchMasterPolicy*/) {
            //this.disabled = true;
            this.isLoading = true;
            getPolicyData({policyNo: this.searchPolicy}).then(result=>{
                this.data = result;
                if(this.data.length > 0) {
                    this.displayTable = true;
                    console.log('Result1 ==> ', this.data);
                    
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
           this.data = result;
           if(this.data.length > 0) {
               this.displayTable = true;
               console.log('Result1 ==> ', this.data);
               
           }
           else{
               this.disabledSearch = false;
               this.showNotification("", 'Data doesn\'t exist', 'info');
           }
           this.isLoading = false;
           this.disabledSearch = true;
           
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
   /* get targetSysOptions() {
        return [
            { label: 'Kavach', value: 'Kavach' },
            { label: 'Jarvis', value: 'Jarvis' },

        ];
    }*/
    
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
    this.dispatchEvent(evt);
    }
}