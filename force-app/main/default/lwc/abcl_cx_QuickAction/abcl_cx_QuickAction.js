import { LightningElement,api,track } from 'lwc';
import getProductsOwned from '@salesforce/apex/ABCL_cx360Controller.getProductsOwned';
import getQuickActions from '@salesforce/apex/ABCL_cx360Controller.getQuickActions';
import createCases from '@salesforce/apex/ABCL_cx360Controller.createCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Abcl_cx_QuickAction extends LightningElement {
    @api recordId;
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
    actionVSFunction = {
        "PIFA": "pifaClick",
        "Send SMS": "sendSMSClick",
        "One Click Docs": "oneClickDoc",
        "PDD Status": "pddStatusClick",
    };
    
    connectedCallback() {
        console.log('Record Id in OpenDocs LWC:', this.recordId);
        
        getQuickActions({customerId: this.recordId}).then(result => {
            this.quickActions=result;
            if(this.quickActions.length>0){
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
    sendSMSClick(event){
        console.log("SMS sent");
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
        console.log('Selected RC', this.isSOAChecked);
    }
    handleICSelect(event) {
        this.isICChecked = event.target.checked;
        console.log('Selected IC', this.isSOAChecked);
    }
    handlePICSelect(event) {
        this.isPICChecked = event.target.checked;
        console.log('Selected PIC', this.isSOAChecked);
    }
    handleNDCSelect(event) {
        this.isNDCChecked = event.target.checked;
        console.log('Selected NDC', this.isSOAChecked);
    }
    handleWelcomeKitSelect(event) {
        this.isWKChecked = event.target.checked;
        console.log('Selected WK', this.isSOAChecked);
    }
    handleLODSelect(event) {
        this.isLODChecked = event.target.checked;
        console.log('Selected LOD', this.isSOAChecked);
    }
    handleCreateCase(){
        if(this.selectedLANId== undefined || this.selectedLANId==''){
            this.showToastMessage('Error', 'Please select a LAN', 'error');
            this.callCreateCase=false;
        }
        if(this.isSOAChecked==false && this.isRCChecked==false && this.isICChecked==false && this.isPICChecked==false && this.isNDCChecked==false && this.isWKChecked==false && this.isLODChecked==false){
            this.showToastMessage('Error', 'Please select atleast one Document type', 'error');
            this.callCreateCase=false;
        }
        //if( (this.selectedLANId != undefined || this.selectedLANId !='') && (this.isSOAChecked==true || this.isRCChecked==true || this.isICChecked==true || this.isPICChecked==true || this.isNDCChecked==true || this.isWKChecked==false || this.isLODChecked==false)){
        if(this.callCreateCase==true){
            console.log('Inside creating a case');
            this.createCases();
        }
    }

    closeModalPopUp(){
        this.showOneClickDoc=false;
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
        createCases({customerId: this.recordId, lanId: this.selectedLANId, createSOACase: this.isSOAChecked, createRSCase: this.isRCChecked, createICCase:this.isICChecked,createPICCase: this.isPICChecked,createNDCCase:this.isNDCChecked,createWKCase:this.isWKChecked,createLODCase:this.isLODChecked})
            .then(result => {
                console.log('case result>>',result);
                if(result==true){
                    this.showToastMessage('Success', 'Case(s) has been created', 'success');
                    this.showOneClickDoc=false;
                }else{
                    this.showToastMessage('Error', 'Case was not created please try again', 'error');
                    this.showOneClickDoc=false;
                }  
                
            }).catch(error => {
                console.log('Error:', error);
            });
    }

    showToastMessage(toastTitle, toastMsg, toastVariant){
        const toastEvent = new ShowToastEvent({
            title: toastTitle,
            message: toastMsg,
            variant: toastVariant
        });
        this.dispatchEvent(toastEvent);
    }
    
}