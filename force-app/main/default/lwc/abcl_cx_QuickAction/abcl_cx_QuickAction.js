import { LightningElement,api,track, wire } from 'lwc';
import getProductsOwned from '@salesforce/apex/ABCL_cx360Controller.getProductsOwned';
import getQuickActions from '@salesforce/apex/ABCL_cx360Controller.getQuickActions';
import createCases from '@salesforce/apex/ABCL_cx360Controller.createCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import createCasesForLAN from '@salesforce/apex/ABCL_CX_LanguagePreference.createCases';
import PREFERREDLANGUAGE_FIELD from '@salesforce/schema/Account.Language_Preference__c';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import LOB_FIELD from '@salesforce/schema/Account.Business_Unit__c';
import ABCL_CX_PREFERRED_LANGUAGE_ACCOUNT from '@salesforce/label/c.ABCL_CX_Preferred_language';
//import getEmailTemplates from '@salesforce/apex/ABCL_CX_SendCommunication.getEmailTemplates';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import getListOfContact from '@salesforce/apex/ASF_SMSCommunicationParser.getListOfContact';
import getListOfTemplate from '@salesforce/apex/ASF_SMSCommunicationParser.getListOfTemplate';
//import getTemplate from '@salesforce/apex/ABCL_CX_Send_SMS.getTemplate';
const ACCOUNT_FIELDS = ['Account.Business_Unit__c','Account.Phone'];
export default class Abcl_cx_QuickAction extends NavigationMixin(LightningElement) {
    @api recordId;
    objectApiName='Account';// need to change to @api---Shagun
    quickActions=[];
    showPIFA=false;
    showSendSMS=false;
    showOneClickDoc=false;
    showPDDStatus=false;
    isSOAChecked=false;
    isRCChecked=false;
    isICChecked=false;
    isPICChecked=false;
    isNDCChecked=false;
    isWKChecked=false;
    isLODChecked=false;
    @track relatedLANs = [];
    showLANs=false;
    showNoLANsError=false;
    selectedLANId;
    callCreateCase=true;
    showNoQuickActionMessage=true;
    showSMSButton=false; //Added by Shagun
    showLanguageButton=false; //Added by Shagun
    isLoading=false;
    successCases = [];
    errorCases = [];
    successMessages=[];
    errorMessages=[];
    selectedDocuments=[];
    showSpinner = false;
    showRecords=false;
    @track assetRecords;
    //For SMS:
    @track showContact={
        showPhone: false,
        showEmail: false,
        showTemplate: false
    }
    checkedToggle=true;
    @track cols={
        emailField: '',
        phoneField: '',
    };
    @track recordDetails = {
        Phone: ''
        //Email: ''
    };
    @track validation={
        validationMessage: '',
        validationTemplateMessage:'',
        showValidation:false,
        showTemplateValidation:false
    };
    displayError = false;
    @track formData = {
        commType: 'SMS',
        template: 'A1202',
        alertCode: '0',
        phoneNumber: '8340600462',
        emailId: ''
    };
    @track relatedPolicies = [];
    showPolicies=false;
    selectedPolicyId;

    lanColumns=[
        { label: 'Loan Account Number', fieldName: 'LAN__c', type: 'text' },
        { label: 'DA Transaction', fieldName: 'DA_Transaction__c', type: 'text' },
        { label: 'Product', fieldName: 'LAN__c', type: 'text' },
        { label: 'Application Type', fieldName: 'Loan_Type__c', type: 'text' },
        { label: 'Loan Status', fieldName: 'Status', type: 'text' },
        { label: 'Disbursal Status', fieldName: 'Loan_Disbursement_Status__c', type: 'text' },
        { label: 'Disbursed Amount', fieldName: 'Disbursed_Amount__c', type: 'currency',typeAttributes: { currencyCode: 'INR'} },
        { label: 'Sanction Amount', fieldName: 'Sanction_Amount__c', type: 'currency',typeAttributes: { currencyCode: 'INR'} },
        { label: 'VAN', fieldName: 'VAN__c', type: 'text' },
    ];

    //Added by Shagun:
    @track currentLanguage ; 
    @track newLanguage = '';
    @track showModal = false; // Controls modal visibility
    selectedlanguage=false;
    isRenderDatatable=true;
    fieldToBeStampedOnCase;
    fieldMappingForCase;

    showSpinner = false;
    @track isButtonDisabled = false;
    showError=false;
    isLoading=false;
    displayMessage='';

    languages=[]; 
    templates=['Medical Emergency', 'Reporting Fraudulent Activities'];
    @track newTemplate = '';
    emailTemplates = [];
    @track selectedEmail = null;
    selectedRecords;
    previewMessage;
    showPreview=false;
    businessUnit;
    phone;



    actionVSFunction = {
        "PIFA": "pifaClick",
        "Send SMS": "sendSMSClick",
        "One Click Docs": "oneClickDoc",
        "PDD Status": "pddStatusClick",
        "Language Preference":"languagePreferenceClick",
    };
    
    connectedCallback() {
        this.isLoading=true;
        this.languages = ABCL_CX_PREFERRED_LANGUAGE_ACCOUNT.split(',').map(item => item.trim()); //Added by Shagun

        console.log('Record Id in OpenDocs LWC:', this.recordId);
        console.log('@@objectApiName',this.objectApiName);
        getQuickActions({customerId: this.recordId}).then(result => {
            this.quickActions=result;
            console.log('Result',result);
            console.log('Result Len',result.length);
            if(result){
                this.showNoQuickActionMessage=false;
            }
            console.log('Quick Actions:', result);
        }).catch(error => {
            console.log('Error getQuickActions:', error);
        });
        console.log('Related actions:', this.quickActions);
    }
    handleActionsSelect(event){
        //get which action is click
        const actionName = event.currentTarget.dataset.action;
        console.log('Selected action:',actionName);
        //get resp function name
        const functionName = this.actionVSFunction[actionName];
        console.log('Related function:',functionName);
        // call the function
        
        if (functionName && typeof this[functionName] === 'function') {
            this[functionName]();
        }

    }
    //Set selected Modal
    pifaClick(event){

    }
 
    
    oneClickDoc(event){
        this.getProductsOwned();
        this.showOneClickDoc=true;
    }
    pddStatusClick(event){

    }
    //Get Selected LAN
    handleLANSelect(event) {
        const selectedRows = event.detail.selectedRows; // This provides an array of selected rows
        if (selectedRows.length > 0) {
            this.selectedLANId = selectedRows[0].Id; // Assuming max-row-selection="1", there will be only one row
            console.log('Selected Row ID:', this.selectedLANId);
            // Add any further logic here
        }
        
    }
    //Get selected Docs
    handleSOASelect(event) {
        this.isSOAChecked = event.target.checked;
        console.log('Selected SOA', this.isSOAChecked);
    }
    handleRepaymentScheSelect(event) {
        this.isRCChecked = event.target.checked;
        console.log('Selected RC', this.isRCChecked);
    }
    handleICSelect(event) {
        this.isICChecked = event.target.checked;
        console.log('Selected IC', this.isICChecked);
    }
    handlePICSelect(event) {
        this.isPICChecked = event.target.checked;
        console.log('Selected PIC', this.handlePICSelect);
    }
    handleNDCSelect(event) {
        this.isNDCChecked = event.target.checked;
        console.log('Selected NDC', this.handleNDCSelect);
    }
    handleWelcomeKitSelect(event) {
        this.isWKChecked = event.target.checked;
        console.log('Selected WK', this.isWKChecked);
    }
    handleLODSelect(event) {
        this.isLODChecked = event.target.checked;
        console.log('Selected LOD', this.isLODChecked);
    }
    handleCreateCase(){
        if(this.selectedLANId== undefined || this.selectedLANId==''){
            this.showToastMessage('Error', 'Please select a LAN', 'error','dismissible');
            this.callCreateCase=false;
        }
        if(this.isSOAChecked==false && this.isRCChecked==false && this.isICChecked==false && this.isPICChecked==false && this.isNDCChecked==false && this.isWKChecked==false && this.isLODChecked==false){
            this.showToastMessage('Error', 'Please select atleast one Document type', 'error');
            this.callCreateCase=false;
        }
        //if( (this.selectedLANId != undefined || this.selectedLANId !='') && (this.isSOAChecked==true || this.isRCChecked==true || this.isICChecked==true || this.isPICChecked==true || this.isNDCChecked==true || this.isWKChecked==false || this.isLODChecked==false)){
        if(this.callCreateCase==true){
            this.isSOAChecked ? this.selectedDocuments.push('SOA') : null;
            this.isRCChecked ? this.selectedDocuments.push('RS') : null;
            this.isICChecked ? this.selectedDocuments.push('IC') : null;
            this.isPICChecked ? this.selectedDocuments.push('PIC') : null;
            this.isNDCChecked ? this.selectedDocuments.push('NDC') : null;
            this.isWKChecked ? this.selectedDocuments.push('WK') : null;
            this.isLODChecked ? this.selectedDocuments.push('LOD') : null;
            this.createCases();
        }
    }

    closeModalPopUp(){
        this.showOneClickDoc=false;
        this.showSMSButton=false;
        this.showLanguageButton=false;
        this.showNoLANsError=false;
    }

    
    getProductsOwned(){
        getProductsOwned({customerId: this.recordId})
        .then(result => {
            console.log('Related Assets:', result);
            if(result.length>0){
                this.relatedLANs = result;
                this.showLANs= true;
            }else{
                this.showNoLANsError=true;
            }
            
        }).catch(error => {
            console.log('Error:', error);
        });

    }
    createCases(){
        this.showSpinner = true;
        this.showLANs=false;
        createCases({customerId: this.recordId, lanId: this.selectedLANId, docs:this.selectedDocuments})
            .then(result => {
                console.log('case result>>',result);
                for (const wrapper of result) {
                    if (wrapper.status == 'Success') {
                        this.successCases.push(wrapper);
                    } else if (wrapper.status == 'Error') {
                        this.errorCases.push(wrapper);
                    }
                }
                this.successCases.forEach((successCase) => {
                    this.successMessages.push('Case #',successCase.newCase.CaseNumber, ' has been created for ',successCase.documentName,'.');
                });
                this.errorCases.forEach((errorCase) => {
                    this.errorMessages.push('Case for ',errorCase.documentName,' was not created due to: ',errorCase.message,'.');
                });

                console.log('Success Cases>>',JSON.stringify(this.successCases));
                console.log('Error Cases>>',JSON.stringify( this.errorCases));
                this.showSpinner = false;
                this.showLANs=true;
                this.showOneClickDoc=false;
                if(this.errorMessages.length>0){
                    const message = this.errorMessages.join('\n');
                    this.showToastMessage('Error', message , 'error','sticky');
                }
                if(this.successMessages.length>0){
                    const message = this.successMessages.join('\n');
                    this.showToastMessage('Success', message , 'Success','sticky');
                }
                this.successCases.forEach((successCase) => {
                    if(successCase.documentName=='List of Documents' && successCase.newCase.Id){
                        this.navigateToRecord(successCase.newCase.Id);
                    }
                });
                this.setDefaultValues();
            }).catch(error => {
                console.log('Error:', error);
            });
    }

    showToastMessage(toastTitle, toastMsg, toastVariant, toastMode){
        const toastEvent = new ShowToastEvent({
            title: toastTitle,
            message: toastMsg,
            variant: toastVariant,
            mode: toastMode
        });
        this.dispatchEvent(toastEvent);
    }
    
    setDefaultValues(){
        this.isSOAChecked=false;
        this.isRCChecked=false;
        this.isICChecked=false;
        this.isPICChecked=false;
        this.isNDCChecked=false;
        this.isWKChecked=false;
        this.isLODChecked=false;
        this.selectedLANId='';
        this.successCases=[];
        this.errorCases=[];
        this.successMessages=[];
        this.errorMessages=[];
        
    }
    
    navigateToRecord(caseId) {
        console.log('Navigation Started');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view',
            },
        });
        console.log('Navigation Complete');
    }

    /*****Added by Shagun *****/

    languagePreferenceClick(event){
        console.log("Language sent");
        this.showLanguageButton=true;
    }

 @wire(getRecord, { recordId: '$recordId', fields: [PREFERREDLANGUAGE_FIELD] })
        wiredRecord({ error, data }) {
            if (data) {
                if (PREFERREDLANGUAGE_FIELD.fieldApiName in data.fields) {
                    this.currentLanguage = data.fields.Language_Preference__c.value;
                }
            } else if (error) {
                console.error(error);
            }
        }

    handleLanguageChange(event) {
        alert('Shagun Selected language');
        this.newLanguage = event.target.value;
        console.log('@@ New Language', this.newLanguage);
        console.log('@@ Current lang', this.currentLanguage);
        //this.selectedlanguage = true;
        if (this.newLanguage === this.currentLanguage) {
            this.showToastMessage('Error', 'Preferred Language and Selected Language cannot be the same.', 'error', 'sticky');
            this.isButtonDisabled = true;
        } else {
            console.log('@@ Else', this.currentLanguage);
            this.isButtonDisabled = false;
        }
    }


    createCasesForLAN(){
    this.showSpinner = true;
    //this.showLANs=false;
    alert('CustomerId:',this.recordId);
    createCasesForLAN({customerId: this.recordId})
            .then(result => {
                console.log('case result>>',result[0]);
                /*for (const wrapper of result) {

                    if (wrapper.status == 'Success') {
                        this.successCases.push(wrapper);
                    } else if (wrapper.status == 'Error') {
                        this.errorCases.push(wrapper);
                    }
                }*/
                    if (result[0].status == 'Success') {
                        this.navigateToRecord(result[0].newCase.Id);
                    } else if (result[0].status == 'Error') {
                        this.showToastMessage('Error', 'Not Created: A case already exist for Preferred language' , 'error','sticky');
                    }
            }).catch(error => {
                console.log('Error:', error);
            });
            this.showLanguageButton = false;
        
    }

    /* showToastMessage(toastTitle, toastMsg, toastVariant, toastMode){
            const toastEvent = new ShowToastEvent({
                title: toastTitle,
                message: toastMsg,
                variant: toastVariant,
                mode: toastMode
            });
            this.dispatchEvent(toastEvent);
        }

     /*navigateToRecord(caseId) {
           console.log('Navigation Started');
           this[NavigationMixin.Navigate]({
               type: 'standard__recordPage',
               attributes: {
                   recordId: caseId,
                   objectApiName: 'Case',
                   actionName: 'view',
               },
           });
           console.log('Navigation Complete');
       }  */   
    
     /*openModal() {
        this.showModal = true;
        console.log('shagun--',this.showModal);
    }

    handleClose() {
        this.showModal = false;
    }*/
    /***********Send SMS **************/

    sendSMSClick(event){
        console.log("SMS sent");
        this.showSMSButton=true;
         this.getProductsOwned();
        //this.getEmailTemplates();
        //this.createFormData(data);
        
    }

        /**
        @wire(getEmailTemplates)
        getEmailTemplates({ data, error }) {
            if (data) {
                console.log('@@ templates',JSON.stringify(data))
                this.emailTemplates = data.map(template => ({
                    value: template.Id,
                    label: template.MasterLabel,
                    body: template.SMS_Template__c
                    //lan:LAN_Required__c
                    //body: template.Body__c
                }));
                console.log('EMail Templates>>',this.emailTemplates);
            } else if (error) {
                console.error('Error fetching email templates: ', error);
            }
        }**/

    handleEmailChange(event) {
        try {
            console.log('@@@ handle template change target:', event.target.value); // Log selected value
            this.selectedRecords = event.target.value; // Assign selected value
            this.lanRequired = event.target.lan;
            //if(this.lanRequired == true && this.selectedRecords){

            //}
            this.showPreview=true;
            this.previewMessage= this.matchingTemplate(this.selectedRecords);
            console.log('@@@ Updated selectedRecords:', this.selectedRecords);
        } catch (error) {
            console.error('Error in handleChange:', error);
        }
    }
    

     matchingTemplate(searchLabel) {
        let templateMessage = "Template not found."; // Default message
        console.log('EMail Templates2>>',JSON.stringify(this.emailTemplates));
        for (let i = 0; i < this.emailTemplates.length; i++) {
            if (this.emailTemplates[i].value == searchLabel) {
                templateMessage = this.emailTemplates[i].body;
                break; // Exit the loop once a match is found
            }
        }

        return templateMessage;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            //console.log('getObjectInfo>>',JSON.stringify(this.data));
            this.objectInfo=data;
        }
        else if(error){
            console.error('Error in objectIfo', error);
            
        }
    }

    





sendSMSButton(event){
alert('Inside doComm');
this.businessUnit ;
this.phone;
console.log('####'+this.businessUnit);
this.getTemplateBody();                    
}


  

@wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            // Fetch Business Unit value
            this.businessUnit = data.fields.Business_Unit__c.value;
            this.phone= data.fields.Phone.value
            } else if (error) {
            console.error('Error fetching account record:', error);
            this.error = error;
        }
    }        
                }
