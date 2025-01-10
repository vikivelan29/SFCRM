import { LightningElement, track, api, wire } from 'lwc';
import getLegacyData from "@salesforce/apex/ABML_LegacyView.abmlGetLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABML_LegacyPageSize';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import abmlGetPersonAccountData from "@salesforce/apex/ABML_LegacyView.abmlGetPersonAccountData";


export default class Abml_LegacyCases extends LightningElement {
    @api recordId;
    @api apiName = 'ABML_Legacy_Case';
    @api payloadInfo;
    displayTable = false;
    displayError = false;
    showChildTable = false;
    leagcyCaseData;
    personAccountData;
    clientId;
    pan;
    startDate;
    endDate;
    code;
    lob;
    agentCode;
    brokerCode;
    loaded = false;
    disabled = false;
    @track displayResult = [];
    statusCode;
    columns;
    errorMessage;
    

    label = {
        errorMessage,
        pageSize
    };
    @wire(abmlGetPersonAccountData, {recordId: '$recordId'})
    wiredPersonAccount({error,data}){
        if(data){
            this.personAccountData=data;
            console.log('Wire Data==>',JSON.stringify(data));
        }
       else if(error){
           console.log('Wire Error==>',error);
       }
    }
    connectedCallback() {
        console.log('***rec'+this.recordId);
        // get columns
        getColumns({configName:'ABMLLegacyCaseView'})
        .then(result => {
                console.log('**rec2>'+JSON.stringify(result));
                this.columns = [
                    {
                        type: "button", label: 'View Case', fixedWidth: 100,typeAttributes: {
                            label: 'View',
                            name: 'View',
                            title: 'View',
                            disabled: false,
                            value: 'view',
                            variant:'neutral',
                        }
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
                // todo: remove hardcoding
                this.showNotification('Error','Error fetching data.','Error');
            });

        
    }

    //Callout to get Legacy data
    fetchLegacyCases() {
        this.displayTable = false;
        this.displayError = false;
        this.data = null;
        this.lob=this.personAccountData.lob;
        if(this.personAccountData.branchCode){
            this.code = this.personAccountData.branchCode;
        }
        else if(this.personAccountData.franchiseeCode){
            this.code = this.personAccountData.franchiseeCode;
        }
        else if(this.personAccountData.agentCode || this.personAccountData.brokerCode){
            this.agentCode = this.personAccountData.agentCode;
            this.brokerCode = this.personAccountData.brokerCode;
        }
        else{
        this.clientId=this.personAccountData.clientCode;      
        this.pan=this.personAccountData.pan;   
        }
        console.log('Client ID '+this.clientId);
        console.log('PAN No '+this.pan);
        console.log('Code '+this.code);
        console.log('Agent Code '+this.agentCode);
        console.log('Broker Code '+this.brokerCode);
        console.log('LOB '+this.lob);
        if(this.checkFieldValidity()) {
            this.disabled = true;
             this.isLoading = true;
            getLegacyData({clientCode: this.clientId, pan: this.pan, code: this.code, agentCode: this.agentCode, brokerCode: this.brokerCode, startDate: this.startDate,
                endDate: this.endDate, lob : this.lob}).then(result=>{
                this.leagcyCaseData = result;
                console.log('Result1 ==> ', result);
                this.isLoading = false;
                if (this.leagcyCaseData && this.leagcyCaseData.returnCode == '1' && this.leagcyCaseData.statusCode == 200) {
                    this.statusCode = this.leagcyCaseData.statusCode;
                    this.loaded = true;
                    this.displayTable = true;
                    this.data = this.leagcyCaseData.legacyCaseResponse;
                    this.disabled = false;
                }
                else if(this.leagcyCaseData && this.leagcyCaseData.statusCode != 0 && (this.leagcyCaseData.returnCode == '2' || this.leagcyCaseData.returnMessage != null)) {
                    console.log('@@@Erro');
                    this.displayError = true;
                    this.loaded = true;
                    this.errorMessage = this.leagcyCaseData.returnMessage;
                    this.disabled = false;
                    //this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                }
                else if(this.leagcyCaseData && this.leagcyCaseData.statusCode == 0){
                    this.disabled = false;
                    this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                } 
            }).catch(error=>{
                console.log('error ==> ', error);
                this.showNotification("Error", this.label.errorMessage, 'error');
                this.isLoading = false;
                this.loaded = true;
                this.disabled = false;
            })
        }

    }
   
    
    callRowAction(event) {
        //this.showChildTable = false;
     //   console.log('Hi>1'+JSON.stringify(event.detail));
        // reset var
        this.showChildTable = true;
        this.payloadInfo = null;
        let result = {};
        
        this.selectedRow = JSON.stringify(event.detail);

        console.log('Hi>1'+ this.selectedRow +'2@@ '+this.statusCode);
        result.statusCode= this.statusCode;
        result.payload = this.selectedRow;
        this.payloadInfo = result;

        setTimeout(() => {             
            this.template.querySelector('c-abfl_base_view_screen').callFunction();
        }, 200);
    }
    startDateChange(event)
    {
        this.startDate = event.target.value;
        console.log('The startDate selected is '+this.startDate );
    }

    endDateChange(event)
    {
        this.endDate = event.target.value;
        console.log('The endDate selected is '+this.endDate );
    }
    checkFieldValidity(){
        this.isLoading = false;
        let checkAllFieldsValid = true;
        checkAllFieldsValid = [
            ...this.template.querySelectorAll('.inpFieldCheckValidity'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        console.log('checkAllFieldsValid'+checkAllFieldsValid);
        return checkAllFieldsValid;
    }

    showNotification(title, message, variant) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    this.dispatchEvent(evt);
    }
}