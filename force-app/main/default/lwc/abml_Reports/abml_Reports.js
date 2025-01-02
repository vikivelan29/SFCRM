import { LightningElement, api, track, wire } from 'lwc';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getReports from "@salesforce/apex/ABML_ReportsIntegration.getReports";
import { getRecord } from 'lightning/uiRecordApi';
import ERRORYEARMESSAGE from '@salesforce/label/c.ABML_Report_Message1';
import SUBMITMESSAGE from '@salesforce/label/c.ABML_ReportMessage2';

const FIELDS = [
    'Case.Account.Active_Date__c'
];

export default class Abml_Reports extends LightningElement {

    @api recordId;
    reportValue;
    startDate;
    endDate;
    minDate;
    minEndDate;
    finacialStart;
    financialEnd;
    finValue;
    @track yearOptions = [];
    datecheck;

    startDatePass;
    endDatePass;
    yeartoYear;
    @track showFinYear = false;
    @track changeYear = true;
    yrOptions = [];
    clientCode;

    get options() {
        return [
            { label: 'Statement of Account', value: 'Statement Of Account' },
            { label: 'Statement of Transaction', value: 'Statement Of Transaction' },
            { label: 'Contract Note', value: 'Contract Note' },
        ];
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.datecheck = data.fields.Account.value?.fields.Active_Date__c.value;
            console.log('chk date >>>>  ',this.datecheck);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.datecheck = undefined;
        }
    }


    handleChange(event) {
        this.reportValue = event.detail.value;
        console.log('reportValue--:',this.reportValue);
    }

    handleYearChange(event){
        this.finValue = event.detail.value;
        console.log('this.finValue--:' , this.finValue);

        // Changes for the Active field check on related Account
        var newCheck = new Date(this.datecheck);
        var newCheckval1 = newCheck.getDate();
        var newCheckval2 = newCheck.getMonth()+1;
        var newCheckval3 = newCheck.getFullYear();

        if(this.finValue < newCheckval3){
            console.log('this.finacialStart--:',this.finValue);

            LightningAlert.open({
                message: ERRORYEARMESSAGE,
                theme: 'warning', 
                label: 'Warning!',
            });
        }

        var yearVal = this.finValue;
        var dateVal = '01';
        var monthVal = '04';
        var dtt = yearVal+'-'+monthVal+'-'+dateVal;
        console.log('finacial year start--:',dtt);
        this.startDate = dtt;
        this.finacialStart = this.startDate;
        //---------------------
        var someDate = new Date(this.startDate);
        console.log('someDate--:',someDate);
        var yearendVal = someDate.getFullYear() + 1;
        var dateendVal = '31';
        var monthendVal = '03';
        var dttt = yearendVal+'-'+monthendVal+'-'+dateendVal;
        console.log('finacial year end--:',dttt);
        this.endDate = dttt;
        this.financialEnd = this.endDate;
        
    }

    startChange(event){
        this.startDate = event.target.value;
        console.log('this.startDate--:',this.startDate);

        if(this.startDate < this.finacialStart || this.startDate > this.financialEnd){
            console.log('this.finacialStart--:',this.finacialStart);
            LightningAlert.open({
                message: 'The start date for the report must fall within the selected financial year date range',
                theme: 'warning', 
                label: 'Warning!',
            });
            //this.startDate = this.finacialStart;
        }
    }

    endChange(event){
        this.endDate = event.target.value;
        if(this.endDate > this.financialEnd || this.endDate < this.finacialStart){
            console.log('this.finacialStart--:',this.finacialStart);
            LightningAlert.open({
                message: 'The end date for the report must fall within the selected financial year date range',
                theme: 'warning', 
                label: 'Warning!',
            });
        }
    }

    // Constructor to generate the year options
    /*constructor() {
        super();
        this.generateYearOptions();
    }*/
    generateYearOptions() {
        const currentYear = new Date().getFullYear();
        const startYear = 2011;
        const endYear = currentYear;
        console.log('currentYear--:',currentYear);
        console.log('startYear--:',startYear);
        console.log('endYear--:',endYear);

        //this.yearOptions = [];
        for (let year = startYear; year <= endYear; year++) {
            this.yrOptions.push({ label: year.toString(), value: year.toString() });
        }
    }
    handleYChange(event) {
        this.selectedYear = event.detail.value;
        console.log('this.selectedYear--:',this.selectedYear);
    }

    connectedCallback(){
       
        console.log('--recordId--:',this.recordId);
        this.generateYearOptions();

     }

     handleClientCodeChange(event){
        this.clientCode = event.target.value;
        console.log('this.clientCode--:',this.clientCode);
     }
     
     onSubmit(){
        var myDate = new Date(this.startDate);
        var dateVal = myDate.getDate();
        var monthVal = myDate.getMonth()+1;
        var yearVal = myDate.getFullYear();
        //console.log('dateVal',dateVal.toString().length);
        //console.log('year',myDate.getFullYear());
        //console.log('month',myDate.getMonth()+1);
        //console.log('day',myDate.getDate());

        if (monthVal.toString().length < 2){
            monthVal = '0' + monthVal;}
        if (dateVal.toString().length < 2){
            dateVal = '0' + dateVal;}
        var dtt = yearVal+'-'+monthVal+'-'+dateVal;
        
        var endDate = new Date(this.endDate);
        var endDateVal = endDate.getDate();
        var endMonthVal = endDate.getMonth()+1;
        var endYearVal = endDate.getFullYear();

        if (endMonthVal.toString().length < 2){
            endMonthVal = '0' + endMonthVal;}
        if (endDateVal.toString().length < 2){
            endDateVal = '0' + endDateVal;}
        var dttt = endYearVal+'-'+endMonthVal+'-'+endDateVal;
        var yr = yearVal+'-'+endYearVal;
        this.yeartoYear = yr;
        console.log('this.yeartoYear',this.yeartoYear);

        this.startDatePass = dtt;
        this.endDatePass = dttt;
        console.log('this.startDatePass',this.startDatePass);
        console.log('this.endDatePass',this.endDatePass);

        // Changes for the Active field check on related Account
        var newCheckSub = new Date(this.datecheck);
        var newCheckSubval1 = newCheckSub.getDate();
        var newCheckSubval2 = newCheckSub.getMonth()+1;
        var newCheckSubval3 = newCheckSub.getFullYear();

        if(this.clientCode =='' || this.clientCode == undefined){
            LightningAlert.open({
                message: 'Client code required',
                theme: 'warning', 
                label: 'Warning!',
            });
        } else if(this.reportValue==undefined || this.reportValue ==''){
            LightningAlert.open({
                message: 'Select Report type',
                theme: 'warning', 
                label: 'Warning!',
            });
        }else if(this.finValue==undefined || this.finValue ==''){
            LightningAlert.open({
                message: 'Select financial year',
                theme: 'warning', 
                label: 'Warning!',
            });
        }else if(this.startDate < this.finacialStart || this.startDate > this.financialEnd){
            console.log('this.finacialStart--:',this.finacialStart);
            LightningAlert.open({
                message: 'The start date for the report must fall within the selected financial year date range',
                theme: 'warning', 
                label: 'Warning!',
            });
            //this.startDate = this.finacialStart;
        } else if(this.endDate > this.financialEnd || this.endDate < this.finacialStart){
            console.log('this.finacialStart--:',this.finacialStart);
            LightningAlert.open({
                message: 'The end date for the report must fall within the selected financial year date range',
                theme: 'warning', 
                label: 'Warning!',
            });
        } else if(this.startDate > this.endDate){
            LightningAlert.open({
                message: 'The start date cannot be greater than end date',
                theme: 'warning', 
                label: 'Warning!',
            });
        } else if (!this.clientCode || !/^\d+$/.test(this.clientCode)) {
            LightningAlert.open({
                message: 'Please enter a valid client Code before submitting.',
                theme: 'warning', 
                label: 'Warning!',
            });
        }
            else if (this.finValue < newCheckSubval3) {
                LightningAlert.open({
                    message: ERRORYEARMESSAGE,
                    theme: 'warning', 
                    label: 'Warning!',
                });
        }
        else{
            
            getReports({ caseRecId: this.recordId, clientCode: this.clientCode, startDate: this.startDatePass, endDate: this.endDatePass, reportType: this.reportValue, financialYear: this.yeartoYear })
        .then(() => {
            //this.showToast('Success','Report type sent succesfully','success');
            //this.successMessage = 'Report type sent succesfully!';
            //this.errorMessage = '';
            LightningAlert.open({
                message: SUBMITMESSAGE,
                theme: 'success', 
                label: 'Success!',
            });
            console.log('im here ');
            this.reportValue = '';
            this.finValue = '';
            this.startDate = '';
            this.endDate = '';
            this.clientCode = '';
            //window.location.reload();
            
               
        })
        .catch((error) => {
            
            //this.showToast('Error sending report',error.body.message,'error');
            //this.errorMessage = 'Error sending report: ' + error.body.message;
            LightningAlert.open({
                message: 'Error sending report',
                theme: 'error', 
                label: 'error!',
            });
            console.log('the id of case is',this.recordId);
            console.log('the error message is ',this.errorMessage);
            //this.successMessage = '';
        });
        }

    }
}