import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import getRelatedRecords from '@salesforce/apex/RNWL_RelatedListHelper.getRelatedRecords';

export default class RNWL_EmailMessageHistory extends NavigationMixin(LightningElement) {
    iconName;
    sectionLabel;
    countOfRecords = 0;
    data;
    columns;
    @api mode;
    @api recordId;
    hasRecords;

    connectedCallback() {
        if (this.mode === 'Best Disposition' || this.mode === 'Last Disposition') {
            this.iconName = 'standard:asset_object';
            this.sectionLabel = this.mode;
        } else {
            this.iconName = 'standard:case_email'
            this.sectionLabel = 'Email Communication';
        }
        getRelatedRecords({ mode : this.mode, recordId : this.recordId })
        .then(result => {
            if (this.mode === 'Email Message') {
                result.emailData?.forEach(each => {
                    each.RecordLink = '/' + each.recordId;
                });
                this.data = result.emailData;
                this.columns = result.columns;
            } else {
                result.data?.forEach(each => {
                    each.RecordLink = '/' + each.Id;
                });
                if (result.data) {
                    let tempData = JSON.parse(JSON.stringify(result.data));
                    let tempColumns = [];
                    this.columns = [];
                    for (let each in result.columns) {
                        if (result.columns[each]?.fieldName?.includes('.')) {
                            let keyForEachRow = result.columns[each].fieldName.replaceAll('.', '');
                            let objName = result.columns[each].fieldName.split('.')[0];
                            let fieldName = result.columns[each].fieldName.split('.')[1];
                            for (let eachRow in tempData) {
                                tempData[eachRow][keyForEachRow] = tempData[eachRow]?.[objName]?.[fieldName];
                            }
                        }
                        let updatedColumn = JSON.parse(JSON.stringify(result.columns[each]));
                        updatedColumn.fieldName = updatedColumn.fieldName.replaceAll('.', '');
                        tempColumns.push(updatedColumn);
                    }
                    this.data = tempData;
                    this.columns = tempColumns;
                }
            }
            this.countOfRecords = this.data ? this.data?.length : 0;
            if (this.data && this.data.length > 0) {
                this.hasRecords = true;
            } else {
                this.hasRecords = false;
            }
        })
        .catch(error=>{
            this.error = error;
            let errMsg = '';                    
            if (error && error.body && error.body.message) {
                errMsg = error.body.message;
            }                  
            this.dispatchEvent(this.showToast('error', errMsg, 'Error!', 'dismissable'));
        })
    }

    //Common method to show toast
    showToast(variant, message, title, mode) {
        return new ShowToastEvent({
            "title": title,
            "message": message,
            "variant": variant,
            "mode": mode
        });
    }
}