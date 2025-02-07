import { LightningElement,api,track,wire } from 'lwc';
import autoSelectAssetBUList from '@salesforce/label/c.ASF_List_of_BUs_To_AutoSelect_Single_Asset';
import abclBusinessUnit from '@salesforce/label/c.ABCL_Business_Unit';
import fetchAssets from "@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets";
export default class Abcl_cx_ProductsOwned extends LightningElement {
    @api recordId;
    @track relatedAssets = [];
    showNoLANMessage=true;
    customLabel = {
        abclBusinessUnit,
        autoSelectAssetBUList
    };
    totalNoOfRecordsInDatatable = 0;
    accBusinessUnit = "";
    @track infoObject = {};
    fieldToBeStampedOnCase;
    selectedAsset = {};
    buttonVariant="neutral";
    connectedCallback() {
        console.log('Record Id Products Owned Section LWC:', this.recordId); // Log or use the recordId as needed
        
    }
    // @wire(getProductsOwned, { customerId: '$recordId' })
    //     productsOwned({ error, data }) {
    //         if (error) {
    //             console.error('Error occured in LWC>>>',error);
    //         } else if (data) {
    //             console.log('Data in asset LWC',data);
    //             this.showNoLANMessage=false;
    //             console.log('showNoLANMessage>>',this.showNoLANMessage);
    //             this.relatedAssets = data.map((asset) => {
    //                 return {
    //                     ...asset, // Spread existing fields
    //                     FinalLabel: `${asset.LAN__c} : ${asset.Loan_Type__c}` // Concatenate two fields
    //                 };
    //             });
                
    //         }
    //     }
    //     handleCheckboxChange(event) {
    //     const selectedId = event.target.value;

    //     // Update the relatedAssets array
    //     this.relatedAssets = this.relatedAssets.map((asset) => {
    //         return {
    //             ...asset,
    //             isChecked: asset.Id === selectedId // Set isChecked to true only for the selected checkbox
    //         };
    //     });
    // }
       @wire(fetchAssets, { accountRecordId: '$recordId' })
    wiredAssets({ error, data }) {
        if (data) {
            this.assetRecords = data.assetRecords;
            this.columns = data.columnNameList;
            //this.populateLwcDatatableData();
            this.showNoLANMessage=false;
            this.totalNoOfRecordsInDatatable = data.assetRecords.length;
            this.accBusinessUnit = data.accBusinessUnit;
            this.setInfoObj();
            console.log('data returned--->',data);
            this.relatedAssets = data.assetRecords.map((asset) => {
                    return {
                        ...asset, // Spread existing fields
                        FinalLabel: `${asset.LAN__r.LAN__c} : ${asset.LAN__r.ProductCode}` // Concatenate two fields
                    };
                });
            console.log('relatedAssets:::',JSON.stringify(this.relatedAssets) )

            // if(this.assetRecords.length > 0 && this.columns.length > 0) {
            //     this.fieldMappingForCase = data.fieldMappingForCase;
            // }

            // //PR1030924-55 Asset records should be auto-selected for manual case creation for accounts with only a single asset.
            // if(this.totalNoOfRecordsInDatatable == 1 && this.customLabel.autoSelectAssetBUList.split(",").includes(getFieldValue(this.account.data, BUSINESS_UNIT_FIELD))) {
            //     //this.preSelectedRows = [data.assetRecords[0].Id];
            //     this.infoObject.isAsset = "true";
            //     this.setFieldMaapingOnCase(data.assetRecords[0]);
            // }

            
        } else if (error) {
            console.log('Error inside--'+JSON.stringify(error));
        }
    }
     setFieldMaapingOnCase(currentSelectedRowRec) {

        let selectedRowRecord  = currentSelectedRowRec;

        let fldToMapToCaseObj = {};
        if(this.fieldMappingForCase && currentSelectedRowRec) {
            let fldsToSearch =  this.fieldMappingForCase.split(",");
            for(let fld of fldsToSearch) {
                let fldToSearch = fld.split(":")[0];
                let fldToMapToCase = fld.split(":")[1];
                fldToMapToCaseObj[fldToMapToCase] = selectedRowRecord[fldToSearch];
            }
            this.fieldToBeStampedOnCase = fldToMapToCaseObj;
        }
    }
    setInfoObj() {
        this.infoObject.businessUnit = this.accBusinessUnit;
        let abclBusinessUnitArr = this.customLabel.abclBusinessUnit.split(",");
        this.infoObject.isAsset = "false";
    }
    handleCheckboxChange(event){
            const selectedValue = event.target.value;
            this.selectedAsset = this.relatedAssets.find(asset => asset.Id === selectedValue);
            const checkboxes = this.template.querySelectorAll('[data-id="customCheckbox"]');
            // Loop through all checkboxes
            checkboxes.forEach((checkbox) => {
                if (checkbox.value != selectedValue) {
                    checkbox.checked = false;
                }
            });
            //this.selectedAsset = this.relatedAssets.find(asset => asset.Id === selectedValue);
        this.selectedAsset = this.assetRecords.find(asset => asset.Id === selectedValue);
        console.log('Selected Asset Details>>>',this.selectedAsset);
        this.infoObject.isAsset = "true";
        console.log('BU>>>1',this.accBusinessUnit);
        this.infoObject.businessUnit = this.accBusinessUnit;
        this.setFieldMaapingOnCase(this.selectedAsset);
    }
    renderedCallback() {
        // Target the lightning-button inside the child component
       setTimeout(() => {
            const button = this.template.querySelector('lightning-button');
            if (button) {
                button.style.fontSize = '18px';
                button.style.backgroundColor = '#4caf50';
                button.style.color = 'white';
            }
        }, 0);
    }

    
}