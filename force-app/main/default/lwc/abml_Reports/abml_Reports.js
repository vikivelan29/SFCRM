import { LightningElement, api, track } from 'lwc';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getReports from "@salesforce/apex/ABML_ReportsIntegration.getReports";

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

    startDatePass;
    endDatePass;
    yeartoYear;
    @track showFinYear = false;
    @track changeYear = true;
    yrOptions = [];

    get options() {
        return [
            { label: 'Statement of Account', value: 'Statement Of Account' },
            { label: 'Statement of Transaction', value: 'Statement Of Transaction' },
            { label: 'Contract Note', value: 'Contract Note' },
        ];
    }

    handleChange(event) {
        this.reportValue = event.detail.value;
        console.log('reportValue--:',this.reportValue);
    }

    handleYearChange(event){
        this.finValue = event.detail.value;
        console.log('this.finValue--:' , this.finValue);

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

        if(this.startDate < this.finacialStart){
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
        if(this.endDate > this.financialEnd){
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
        const startYear = currentYear - 5;
        const endYear = startYear + 5;
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
        if(this.reportValue==undefined || this.reportValue ==''){
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
        }else if(this.startDate < this.finacialStart){
            console.log('this.finacialStart--:',this.finacialStart);
            LightningAlert.open({
                message: 'The start date for the report must fall within the selected financial year date range',
                theme: 'warning', 
                label: 'Warning!',
            });
            //this.startDate = this.finacialStart;
        } else if(this.endDate > this.financialEnd){
            console.log('this.finacialStart--:',this.finacialStart);
            LightningAlert.open({
                message: 'The end date for the report must fall within the selected financial year date range',
                theme: 'warning', 
                label: 'Warning!',
            });
        }
        else{
            
            getReports({ caseRecId: this.recordId, startDate: this.startDatePass, endDate: this.endDatePass, reportType: this.reportValue, financialYear: this.yeartoYear })
        .then(() => {
            //this.showToast('Success','Report type sent succesfully','success');
            //this.successMessage = 'Report type sent succesfully!';
            //this.errorMessage = '';
            LightningAlert.open({
                message: 'Report details sent successfully',
                theme: 'success', 
                label: 'Success!',
            });
            console.log('im here ');
            this.reportValue = '';
            this.finValue = '';
            this.startDate = '';
            this.endDate = '';
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