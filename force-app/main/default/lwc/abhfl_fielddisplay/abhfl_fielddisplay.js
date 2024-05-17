import { LightningElement,api } from 'lwc';

export default class Abhfl_fielddisplay extends LightningElement {
    @api columnName;
    @api rowData;
    @api colValue;
    @api columnType;
    @api columnEditable;
    @api options;
    @api disableEditField;
    @api currStage;
    @api userId;
    @api ownerId;
    @api stagesAllowingFieldEdit;
    @api impactLogic;
    isLAN
    assetURL;
    displayNumber;
    displayCheckbox;
    displayDate;
    displayPercentage;
    displayInput;
    inputType;
    formatType;
    stepValue;
    displayCombo;
    loanDisbursementStatus;
    defaultDisableVal = true;

    
    connectedCallback(e){
        this.defaultDisableVal = this.disableEditField;  
        this.loanDisbursementStatus = this.rowData["asset"].Loan_Disbursement_Status__c;      
        this.setColValue();
        if(this.columnName == 'Revised_EMI_Tenure__c'){
            if(this.currStage == 'CPU PP' && this.userId == this.ownerId){
                this.defaultDisableVal = false;
            } else {
                this.defaultDisableVal = true;
            }
        }
    }

    @api setColValue(){
        let colName = this.columnName;
        let objName;
        if (colName.includes('.')){
            objName = colName.split('.')[0];
            colName = colName.split('.')[1];
        } else {
            objName = 'detail';
        }
        if(!this.columnEditable){
            switch (this.columnType) {
                case 'BOOLEAN':
                    this.displayCheckbox = true;
                    break;
                case 'DOUBLE':
                    this.displayNumber = true;
                    break;
                case 'PERCENT':
                    this.displayPercentage = true;
                    break;
                case 'DATE':
                    this.displayDate = true;
                    break;
                default:
            }
            if(colName == 'LAN__c'){
                this.isLAN = true;
                this.assetURL = '/'+ this.rowData.asset.Id;
            }
        }else{
            this.displayInput = true;
            switch (this.columnType) {
                case 'BOOLEAN':
                    this.inputType = 'checkbox';
                    break;
                case 'DOUBLE':
                    this.inputType = 'number';
                    this.formatType = 'currency';
                    break;
                case 'PERCENT':
                    this.inputType = 'number';
                    this.formatType = 'percent-fixed';
                    this.stepValue = '0.01';
                    break;
                case 'DATE':
                    this.inputType = 'date';
                    break;
                case 'PICKLIST':
                    this.displayInput = false;
                    this.displayCombo = true;
                    break;
                default:
                    this.inputType = 'text';
            }
            if(this.columnName == 'Revised_EMI_Tenure__c'){
                this.formatType = 'number';
            }
        }
        let value = this.rowData[objName][colName];
        if(value){
            this.colValue = value;
        }
    }

    handleChange(e){
        const selectEvent = new CustomEvent('selection', {
            detail : { 
                        fieldName : this.columnName,
                        assetId : this.rowData.asset.Id,
                        value : e.target.value}});
        // Fire the custom event
        this.dispatchEvent(selectEvent);
    }

    handleClick(e){
        if(this.userId != this.ownerId || (this.stagesAllowingFieldEdit && this.stagesAllowingFieldEdit.length > 0 && !this.stagesAllowingFieldEdit.includes(this.currStage)) && this.columnName != 'Revised_EMI_Tenure__c'){
            const selectEvent = new CustomEvent('checkeditpermissions',{});
            // Fire the custom event
            this.dispatchEvent(selectEvent);
            this.closeModal();
        }
        if(this.columnName == 'Revised_EMI_Tenure__c'){
            if(this.currStage != 'CPU PP'){
                const selectEvent = new CustomEvent('checkeditpermissions',{});
                // Fire the custom event
                this.dispatchEvent(selectEvent);
                this.closeModal();
            }
        }
    }

    renderedCallback(){
        if(this.columnType == 'PICKLIST'){
            this.template.querySelector("select[name=selection]").value = this.colValue;
            //this.template.querySelectorAll("c-abhfl_fielddisplay").forEach(result=>{result.value = this.colValue;});
        }
        this.impactLogicForPartiallyDisbLoan();
    }   

    impactLogicForPartiallyDisbLoan() {
        if(this.columnName == "Impact__c" && this.displayCombo && this.impactLogic && this.loanDisbursementStatus == "Partially") {
            let getSelect = this.template.querySelector('[name="selection"]');
            let options = getSelect.options;

            for(let columnName of options) {
                if(columnName.textContent === "EMI") {
                    let eObj = {target : {value : "EMI"}};
                    columnName.selected = true;
                    this.template.querySelector('[name="selection"]').disabled = true;
                    this.handleChange(eObj);
                }
            }
        }
    }

    @api
    refresh(e){
        //this.connectedCallback();
        //this.displayInput = !this.displayInput;
        //this.displayInput = !this.displayInput;
        if(this.columnType == 'PICKLIST'){
            this.template.querySelector("select[name=selection]").disabled = e;
            this.impactLogicForPartiallyDisbLoan();
        }
        if(this.displayInput){
            this.template.querySelector("lightning-input").disabled = e;
        }
        let isDisabled = true;
        if(this.columnName == 'Revised_EMI_Tenure__c'){
            if(this.currStage == 'CPU PP' && this.userId == this.ownerId){
                isDisabled = false;
            } else {
                isDisabled= true;
            }
            this.template.querySelector("lightning-input").disabled = isDisabled;
        }
        
    }

    @api
    checkValidity(e){
        if(this.template.querySelector('lightning-input')){
            if(this.columnName == 'Revised_EMI_Tenure__c'){
                return this.template.querySelector('lightning-input').reportValidity();
            } else if(this.columnName == 'Revised_ROI__c'){
                if(this.template.querySelector('lightning-input').value < 100){
                    return true;
                } else {
                    return false;
                }
            }
        }else {
            return true;
        }
    }
    
}