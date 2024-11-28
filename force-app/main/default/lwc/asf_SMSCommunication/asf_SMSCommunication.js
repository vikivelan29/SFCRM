import { LightningElement,api, wire, track } from 'lwc';

import getListOfContact from '@salesforce/apex/ASF_SMSCommunicationParser.getListOfContact';
import getListOfTemplate from '@salesforce/apex/ASF_SMSCommunicationParser.getListOfTemplate';
import getTemplate from '@salesforce/apex/ASF_SMSComponentHandler.getTemplate';

import WAMsgDelivered from '@salesforce/label/c.ASF_SMS_Delivered_Sucess';
import WAMsgNotDelivered from '@salesforce/label/c.ASF_SMS_Delivered_Failed';
//import contactNotEnroled from '@salesforce/label/c.Contact_Whatsapp_Not_Enroled';
import CCCTemplateMapping from '@salesforce/label/c.ASF_No_SMSemplate_On_CCC';
import WANoContactAvailable from '@salesforce/label/c.ASF_Whatsapp_No_Contacts_Available';


//import initiateCallout from '@salesforce/apex/Asc_IntegrationCalloutHandler.initiateCallout';

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Mobile Phone', fieldName: 'phone' }
];

const tempColumns = [
    { label: 'Template Name', fieldName: 'label' }
];


export default class Asf_SMSCommunication extends LightningElement {

    label = {
        WAMsgDelivered,
        WAMsgNotDelivered,
        //contactNotEnroled,
        CCCTemplateMapping,
        WANoContactAvailable
    };


    @api recordId;

    @track data;
    @track columns = columns;
    @track searchString;
    @track initialRecords = [];
    @track selectedCon;
    @track isEnrolmentBtn;
    @track isEnroled;
    @track contactDTSelectedRows = [];
    @track templateDTSelectedRows = [];
    @track message;
    @track msgSuccess;
    @track msgWarning;
    @track selectedTemplate;
    @track templateInitialRecords;
    @track isTemplateSelected;
    @track templateData = [];
    @track templateColumns = tempColumns;
    @track templateBody;
    @track generateTemplateOnly;
    @track templateMap;
    @track contactSearchWord;
    @track templateSearchWord;
    @track spinner;
    

    @track currentStep = '1';

    @track sendSMS = false;

    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }
    
    get templateSize(){
        return this.templateInitialRecords.length;
    }

    get isStepOne() {
        return this.currentStep === "1";
    }
 
    get isStepTwo() {
        return this.currentStep === "2";
    }
 
    get isStepThree() {
        return this.currentStep === "3";
    }

    get isStepFour() {
      return this.currentStep === "4";
  }
 
    get isEnableNext() {
        if(this.currentStep==="1" && this.isEnrolmentBtn === true){
          return true;
        }else if(this.currentStep==="2" && this.isTemplateSelected === true){
          return true;
        }
        return false;
    }
 
    get isEnablePrev() {
        console.log('Prev Current Step >>> '+this.currentStep);
        return this.currentStep === "2" || this.currentStep === "3";
    }
 
    get isEnableFinish() {
        return this.currentStep === "3";
    }
 
    handleNext(){
        if(this.currentStep == "1"){
            this.spinner = true;
            //this.checkEnrolment();
            this.getTemplates();
        }else if(this.currentStep == "2"){
            this.generateTemplateOnly = true;
            this.spinner = true;
            this.getTemplateBody();
        }
    }
 
    handlePrev(){
        if(this.currentStep == "3"){
            this.currentStep = "2";
        }else if(this.currentStep == "2"){
          this.currentStep = "1";
        }
    }

    resetTemplateStage(){
          this.templateDTSelectedRows = [];
          this.isTemplateSelected = false;
          this.templateSearchWord = '';
          console.log('on BACK Contact Selcted is : '+this.contactDTSelectedRows);
    }
 
    handleFinish(){
        console.log('Finished Method called!!! ');
        this.generateTemplateOnly = false;
        this.spinner = true;
        this.sendSMS = true;
        this.getTemplateBody();
    }

    get isSearchEnabled(){
      return this.initialRecords.length>1;
    }

    get isTemplateSearchable(){
        return this.templateInitialRecords.length>1;
    }
    

    connectedCallback(){
        this.generateTemplateOnly = true;
        this.isEnroled = false;
        this.isEnrolmentBtn = false;
        this.msgSuccess = false;
        this.msgWarning = false;
        this.spinner = true;
    }
 
    @wire(getListOfContact , { srId: '$recordId' })
    wiredRecordsMethod({ error, data }) {
        console.log('Wired Data >>> '+JSON.stringify(data));
        if (data) {
          console.log("Data Received >>>"+JSON.stringify(data));
          this.spinner = false;
          this.data = data;
          this.initialRecords = data;
          if(data.length==1){
            this.contactDTSelectedRows = [];
            this.contactDTSelectedRows.push(data[0].id);
            this.isEnrolmentBtn = true;
            this.selectedCon = data[0];
          }
          if(data.length==0){
            this.currentStep = "4";
            this.message = this.label.WANoContactAvailable;
            this.msgWarning = true;
          }
        } else if (error) {
          console.log("Error Received >>>"+error);
          this.isEnroled = false;
          this.data = undefined;
        }
    }

    handleSearch(event){
        console.log('Handle Search triggered!!!');
        const searchKey = event.target.value.toLowerCase();
        let type = event.target.dataset.name;
        if (searchKey) {
            if(type=='Contact Search'){
                this.contactSearchWord = event.target.value;
                this.template.querySelector('[data-name="Contact Datatable"]').selectedRows=[];
                this.isEnrolmentBtn = false;
                this.isEnroled = false;
                this.data = this.filterData(this.initialRecords.map(temp => ({id:temp.id, name: temp.name, phone: temp.phone })),searchKey);
            }else{
                this.templateSearchWord = event.target.value;
                this.template.querySelector('[data-name="Template Datatable"]').selectedRows=[];
                this.isTemplateSelected = false;
                this.templateData = this.filterData(this.templateInitialRecords.map(temp => ({id:temp.id, label: temp.label })),searchKey);
            }
        }else{
            if(type=='Contact Search'){
                this.data = this.initialRecords;
            }else{
                this.templateData = this.templateInitialRecords;
            }
        }
    }


    filterData(records,searchKey){
        let searchRecords = [];
        for (let record of records) {
            let valuesArray = Object.values(record);
            for (let val of valuesArray) {
                console.log('val is ' + val);
                let strVal = String(val);
                if (strVal) {
                    if (strVal.toLowerCase().includes(searchKey)) {
                        searchRecords.push(record);
                        break;
                    }
                }
            }
        }
        console.log('Matched Accounts are ' + JSON.stringify(searchRecords));
        return searchRecords;
    }
    
    getSelectedName(event){
        this.resetTemplateStage();
        var selected = this.template.querySelector('[data-name="Contact Datatable"]').getSelectedRows()[0];
        this.selectedCon = selected;
        this.contactDTSelectedRows = [];
        this.contactDTSelectedRows.push(selected.id);
        this.isEnrolmentBtn = true;
        console.log(this.isEnrolmentBtn+"   "+JSON.stringify(selected)+'selected row '+selected.name+" >>> "+selected.id);
    }

    getSelectedTemplate(){
        var selected = this.template.querySelector('[data-name="Template Datatable"]').getSelectedRows()[0];
        selected  = this.templateInitialRecords.find(o => o.id === selected.id);
        this.selectedTemplate = selected;
        this.templateDTSelectedRows = [];
        this.templateDTSelectedRows.push(selected.id);
        this.isTemplateSelected = true;
        console.log(this.isTemplateSelected+"   "+JSON.stringify(selected)+'selected row '+selected.mdtName+" >>> "+selected.id);
    }

    checkEnrolment(){
        this.isenroled = false;
        let lwcReqObj = {"mobile_phone" : this.selectedCon.phone};
        initiateCallout({
            strSettingName: 'WhatsappEnrolmentEnquiry_API',
            strRecordId: this.selectedCon.id,
            strLWCCardDetails: JSON.stringify(lwcReqObj)
        })
        .then(result => {
            this.spinner = false;
            console.log('Enrolment API DATA : '+JSON.stringify(result));
            if(result != null && result != ''){
              console.log('API Enrolment response code : ',result?.strResponseStatusCode);
                if(result.strResponseStatusCode == '200'){
                    let res = JSON.parse(result.strResponseRawJSON);
                    this.isenroled = res?.data?.optInFlag=='Y'?true:false;
                    console.log('API Enrolment check flag '+this.isenroled);
                    if(this.isenroled){
                        this.spinner = true;
                        this.getTemplates();
                    }else{
                        //this.message = this.label.contactNotEnroled;
                        this.msgWarning = true;
                        this.currentStep = "4";
                    }
                }else{
                    throw "Received Status Code 200, Error with the optInFlag";
                }
            }
        })
        .catch(error => { 
            console.log("Error Received >>>"+JSON.stringify(error));
            this.spinner = false;
            this.currentStep = "4";
            this.message = "Error retriving the enrolment status. Please contact the administrator.";
            this.msgSuccess = false;
        });

        return this.isenroled;
        
    }

    getTemplates(){

        getListOfTemplate({
            caseId: this.recordId
        })
        .then(data => {
            console.log("Template Data Received >>>"+JSON.stringify(data));
            this.spinner = false;
            if(data.length==0){
                this.currentStep = "4";
                this.message = this.label.CCCTemplateMapping;
                this.msgWarning = true;
            }else{
                this.templateData = data;
                this.templateInitialRecords = data;
                this.currentStep = "2";
            }
        })
        .catch(error => { 
            console.log("Error Received >>>"+JSON.stringify(error));
            this.spinner = false;
            this.currentStep = "4";
            this.message = "Error retriving the list of whatsapp Template Name. Please contact the administrator.";
            this.msgSuccess = false;
        });
    }

    getTemplateBody(){
        console.log('@@@ GENERATION Template BODY '+this.recordId+'  '+this.selectedTemplate.mdtName);
        getTemplate({
            caseId: this.recordId,
            templateMetaData: this.selectedTemplate.mdtName,
            isGenerateOnlyTemplate: this.generateTemplateOnly,
            conId: this.selectedCon.id,
            finalSend : this.sendSMS
        })
        .then(data => {
            console.log("Template BODY Received >>>"+JSON.stringify(data));
            this.spinner = false;
            if(this.generateTemplateOnly){
                this.templateMap = JSON.parse(data);                    
                this.templateBody = this.templateMap[0].template;
                this.currentStep = "3";
            }else{
                this.currentStep = "4";
                this.message = this.label.WAMsgDelivered;
                this.msgSuccess = true;
            }
        })
        .catch(error => { 
            console.log("Error Received >>>"+JSON.stringify(error));
            this.spinner = false;
            this.currentStep = "4";
            if(!this.generateTemplateOnly){
                this.message = this.label.WAMsgNotDelivered;
            }else{
                this.message = "Preview Error. Please contact the administrator.";
            }
            this.msgSuccess = false;
        });
    }


}