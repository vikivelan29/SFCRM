import { LightningElement, api,track } from 'lwc';

export default class Abhi_HHS_Active extends LightningElement {


    errorMessages

    @api recordId;
    @track isLoading = false;

    handleUploadStart() {
        this.isLoading = true;
        this.displayError = false;
        let customerId = this.recordId;

        getHhsActiveAge({customerId:customerId})
        .then(result => {
            console.log('result---->', result);
            this.isLoading = false;
            this.showDataTable = true;

            if(result.StatusCode == 1000 && Object.keys(result.HHSDetails.responseMap).length > 0) {
                this.setupColumns(result);
                this.processResponse(result);
            } else if (result.StatusCode == 1000 && Object.keys(result.HHSDetails.responseMap).length ===0){
                this.setupColumns(result);
                this.processResponse(result);
                this.resultMessageValue = result.HHSDetails.serviceMessages[0].businessDesc;

            } else if (result.StatusCode == 1002 && Object.keys(result.HHSDetails.responseMap).length > 0){
                this.showDataTable = false;
                this.errorMessages = result.Message;
                this.displayError = true;
                this.showTable = true;
                this.processResponse(result);

            }
            else {
                this.showDataTable = false;
                this.errorMessages = result.Message;
                this.resultMessageValue = result.HHSDetails.serviceMessages[0].businessDesc;
                this.displayError = true;
            
            }
            
        })
        .catch(error => {
            this.isLoading = false;
            this.displayError = true;
            this.errorMessages = error.body.message;
        });
    }

    handleUploadEnd() {
        this.isLoading = false;
    }
    childmessage = false;

    updateMessage(event) {
        this.message = event.detail.message;
    }

    processResponse(response) {
        console.log('API Response:', response);
        this.recordTable = null;
        this.recordTable2 = [];
        this.currentPage = 1;
        
        if (response && response.StatusCode === '1000'|| response.StatusCode === '1002') {
            console.log('response code', response.StatusCode);
          
            if(response.activeAge!=null){
                const activeAge = response.activeAge;
            console.log('activeAge-->',activeAge);

            const tableData = [{
                CustomerNo: activeAge.CustomerNo,
                ActualAge: activeAge.ActualAge,
                MultiplyAge: activeAge.MultiplyAge,
                HeartAge: activeAge.HeartAge,
                CalculationDate: activeAge.CalculationDate
            }];
            this.recordTable2 = tableData;  // Ensure this is populated as needed
            this.showDataTable = true;
            this.displayError = false;
        }
        else{
            this.showDataTable = false;
            this.displayError = true;
            this.errorMessages = response.Message;
        }
           // Check if HHSDetails and serviceMessages exist
        if (response.HHSDetails && Array.isArray(response.HHSDetails.serviceMessages)) {
            const serviceMessages = response.HHSDetails.serviceMessages;

            // Find if there is a message with "Result found" or "No Result found"
            const resultMessage = serviceMessages.find(msg =>
                msg.businessDesc === "Result found" || msg.businessDesc === "No Result found"
            );
            
            if (resultMessage) {
                if (resultMessage.businessDesc === "Result found" && response.HHSDetails.responseMap && Object.keys(response.HHSDetails.responseMap).length > 0) {
                
                        const resultsList = response.HHSDetails.responseMap.resultsList;
                        const tierLevelName = resultsList.tierLevelName;
                        const activities = resultsList.activities;
                            //console.log('Activities:', JSON.stringify(activities, null, 2));

                            let table = [];
                            if (response.HHSDetails.operationStatus === 'SUCCESS') {
                                table.push({
                                    attributeCode: 'Current Score',
                                    attributeValue: tierLevelName || ''
                                });


                                let attributeValues = {
                                    'Total Cholesterol': '',
                                    'Fasting Blood Sugar (mg/dl)': ''
                                };

                                activities.forEach(activity => {
                                    if (activity.name === "Total cholesterol") {
                                        attributeValues['Total Cholesterol'] = activity.value || '';
                                    } else if (activity.name === "Fasting Blood Sugar (mg/dl)") {
                                        attributeValues['Fasting Blood Sugar (mg/dl)'] = activity.value || '';
                                    }
                                    if (activity.attributes && Array.isArray(activity.attributes) && activity.attributes.length > 0) {
                                        activity.attributes.forEach(attr => {
                                            const label = ATTRIBUTE_CODE_LABELS[attr.attributeCode] || attr.attributeCode;
                                            if (ALLOWED_ATTRIBUTES.includes(label)) {
                                                table.push({
                                                    attributeCode: label,
                                                    attributeValue: attr.attributeValue || ''
                                                });
                                            }
                                        });
                                    }
                                });
        
                                // Add specific attributes to the table
                                Object.keys(attributeValues).forEach(key => {
                                    table.push({
                                        attributeCode: key,
                                        attributeValue: attributeValues[key]
                                    });
                                });
        
                                this.table = table;
                                console.log('Table Data:', JSON.stringify(this.table, null, 2));
                                this.showTable = true;
                            } else {
                                this.table = [];
                                this.noResultsMessage = true;
                                //this.resultMessageValue = response.HHSDetails.serviceMessages[0].businessDesc;
                            }
                   
                } else if (resultMessage.businessDesc === "No Result found") {
                    console.log('resultMessage.businessDesc', resultMessage.businessDesc);
                    // Handle case where "No Result found" is present
                    this.resultMessageValue = response.HHSDetails.serviceMessages[0].businessDesc;
                }
            } else {
                this.noResultsMessage = resultMessage.businessDesc;
            }
        } else {
            this.noResultsMessage = true;
        }
        } else {
            //this.errorMessages = 'No valid response from API';
            this.errorMessages = response.Message;
            this.displayError = true;
        }
    }

    formatNumber(value) {
        return Number(value).toLocaleString('en-US');
    }

    updateTableData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        
    }

    handleRefresh() {
        this.loadData();
    }

    firstPage() {
        this.currentPage = 1;
        this.updateTableData();
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updateTableData();
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updateTableData();
        }
    }

    lastPage() {
        this.currentPage = this.totalPages;
        this.updateTableData();
    }

    get bDisableFirst() {
        return this.currentPage === 1;
    }

    get bDisableLast() {
        return this.currentPage === this.totalPages;
    }

    get pageNumber() {
        return this.currentPage;
    }
}