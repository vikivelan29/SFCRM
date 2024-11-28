import { LightningElement, api, track } from 'lwc';
import fetchRoiHistory from '@salesforce/apex/ABHFL_RoiHistoryClass.fetchRoiHistory';

export default class Abhfl_ROIHistory extends LightningElement {

    @api recordId;
    sectionClosed = true;
    @track activeSections =['roiHistory'];
    isLoading = false;
    @track roiData = [];
    @track roiColumns = [];
    receivedResponse=true;
    noResponseFromServer = '';

    getRoiHistoryDetails(){
        this.sectionClosed = true;
        this.isLoading = true;
        fetchRoiHistory({assetId:this.recordId})
            .then((result)=>{
                console.log('Response:'+JSON.stringify(result));
                console.log('result.data:'+JSON.stringify(result.data));
                if(result && result.data){
                    this.roiColumns = result.columns;
                    this.roiData = [...result.data];
                    this.receivedResponse = true;
                    this.noResponseFromServer = '';
                }else{
                    this.receivedResponse = false;
                    this.noResponseFromServer = 'Could not get details. Please try again later.';
                }
                this.sectionClosed = false;
                this.isLoading = false;
            })
            .catch((error)=>{
                this.sectionClosed = true;
                this.isLoading = false;
                console.error('Error in fetching data:'+JSON.stringify(error));
            })
    }

    handleToggleSection(event){
        /*this.isLoading = true;
        if(event.detail.openSections.length>0){
            let selectedSection = this.outerSections.find(record=>event.detail.openSections.includes(record.sectionName));
            if(selectedSection.tabular==false && selectedSection.sectionFieldsMap){
                let fields = selectedSection.sectionFieldsMap;
                for(let key in fields){
                    this.outerFieldsData.push({fieldName:key,label:key,value:fields[key]});
                }
                this.fieldsInOuterColumn1 = this.outerFieldsData.slice(0, Math.ceil(this.outerFieldsData.length / 2));
                this.fieldsInOuterColumn2 = this.outerFieldsData.slice(Math.ceil(this.outerFieldsData.length / 2));        
            }
        }
        this.isLoading = false;*/
    }

    /*handleToggleSectionInner(event){
        this.innerFieldsData = [];
        this.isLoading = true;
        if(event.detail.openSections.length>0){
            let selectedSection = this.innerSections.find(record=>event.detail.openSections.includes(record.sectionName));
            if(selectedSection.tabular==false && selectedSection.sectionFieldsMap){
                let fields = selectedSection.sectionFieldsMap;
                for(let key in fields){
                    this.innerFieldsData.push({fieldName:key,label:key,value:fields[key]});
                }
                this.fieldsInInnerColumn1 = this.innerFieldsData.slice(0, Math.ceil(this.innerFieldsData.length / 2));
                this.fieldsInInnerColumn2 = this.innerFieldsData.slice(Math.ceil(this.innerFieldsData.length / 2))
            }
        }
        this.isLoading = false;
    }*/

}