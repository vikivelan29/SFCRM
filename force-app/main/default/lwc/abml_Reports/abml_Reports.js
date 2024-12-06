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

    get options() {
        return [
            { label: 'Statement of Account', value: 'Statement Of Account' },
            { label: 'Statement of Transaction', value: 'Statement Of Transaction' },
            { label: 'Contract Note', value: 'Contract Note' },
        ];
    }

    get financeYears() {
        console.log('--financeYears--',this.yearOptions);
        return this.yearOptions;
        /*return [
            { label: '2022', value: '2022' },
            { label: '2023', value: '2023' },
            { label: '2024', value: '2024' },
        ];*/
    }

    handleChange(event) {
        this.reportValue = event.detail.value;
        console.log('reportValue--:',this.reportValue);
    }

    handleYearChange(event){
        this.finValue = event.detail.value;
        console.log('this.finValue--:' , this.finValue);
        this.showFinYear = true;
        this.changeYear = false;
        //const selectedOption = event.detail.value;
        //console.log('selectedOption=' + selectedOption);

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

    changeFinYear(){
        this.showFinYear = false;
        this.changeYear = true;
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

        /*console.log('this.startDate--:',this.startDate);
        var someDate = new Date(this.startDate);
        var yearVal = someDate.getFullYear();
        console.log('yearVal--:',yearVal);
        var dateVal = '01';
        var monthVal = '04';
        var dtt = yearVal+'-'+monthVal+'-'+dateVal;
        console.log('finacial year start--:',dtt);
        this.finacialStart = dtt;*/
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

        /*var someDate = new Date(this.endDate);
        var yearVal = someDate.getFullYear();
        console.log('yearVal--:',yearVal);
        var dateVal = '31';
        var monthVal = '03';
        var dtt = yearVal+'-'+monthVal+'-'+dateVal;
        console.log('finacial year end--:',dtt);
        this.financialEnd = dtt;*/
    }

    connectedCallback(){
        var someDate = new Date();
        var yearVal = someDate.getFullYear() - 6;
        console.log('yearVal--:',yearVal);
        //let arr = [];
        for(let i=0;i<6;i++){
            yearVal = yearVal+1;
            //this.yearOptions.push(yearVal); 
            //arr.push({label: yearVal, value: yearVal});
            this.yearOptions = [...this.yearOptions ,{value: yearVal , label: yearVal}];   
            console.log('yearVal123--:',yearVal);
        }
        //this.yearOptions = arr;
        console.log('yearOptions--:',this.yearOptions);
       
        console.log('--recordId--:',this.recordId);
        /*var date = new Date();//.toISOString().slice(0,10);
        var endDate = new Date();
        
        date.setFullYear( date.getFullYear() - 5 );
        this.minDate = date.toISOString().slice(0,10);
        
        console.log('Past 5 Years--:',this.minDate);
        console.log('reportValue--:',this.reportValue);

        this.minEndDate = endDate.toISOString().slice(0,10);*/

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
        var dtt = dateVal+'-'+monthVal+'-'+yearVal;
        
        var endDate = new Date(this.endDate);
        var endDateVal = endDate.getDate();
        var endMonthVal = endDate.getMonth()+1;
        var endYearVal = endDate.getFullYear();

        if (endMonthVal.toString().length < 2){
            endMonthVal = '0' + endMonthVal;}
        if (endDateVal.toString().length < 2){
            endDateVal = '0' + endDateVal;}
        var dttt = endDateVal+'-'+endMonthVal+'-'+endYearVal;
        var yr = yearVal+'-'+endYearVal;
        this.yeartoYear = yr;
        console.log('this.yeartoYear',this.yeartoYear);

        this.startDatePass = dtt;
        this.endDatePass = dttt;
        console.log('this.startDatePass',this.startDatePass);
        console.log('this.endDatePass',this.endDatePass);
        if(this.reportValue==undefined){
            LightningAlert.open({
                message: 'Select Report type',
                theme: 'warning', 
                label: 'Warning!',
            });
        }else if(this.finValue==undefined){
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
        }
        else{
            
            getReports({ caseRecId: this.recordId, startDate: this.startDatePass, endDate: this.endDatePass, reportType: this.reportValue, financialYear: this.yeartoYear })
        .then(() => {
            //this.showToast('Success','Report type sent succesfully','success');
            //this.successMessage = 'Report type sent succesfully!';
            //this.errorMessage = '';
            LightningAlert.open({
                message: 'Report details sent succesfully',
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