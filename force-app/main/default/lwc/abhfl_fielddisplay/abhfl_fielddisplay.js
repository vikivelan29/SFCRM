import { LightningElement,api } from 'lwc';

export default class Abhfl_fielddisplay extends LightningElement {
    @api columnName;
    @api rowData;
    @api colValue;
    @api columnType;
    @api columnEditable;
    @api options;
    @api disableEditField;
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

    connectedCallback(e){
        this.setColValue();
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

    renderedCallback(){
        if(this.columnType == 'PICKLIST'){
            this.template.querySelector("select[name=selection]").value = this.colValue;
        }
    }
    
}