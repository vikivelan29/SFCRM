import { LightningElement, track, api} from 'lwc';
import {invokeCore} from 'c/abcl_base_view';

export default class ABFL_DynamicScreen extends LightningElement {
	title;
	screenjson;
	show=false;
	tblcolumns;
	tableData;
	isRenderDatatable = false;
	col = [
		{ label: 'Label', fieldName: 'name' },
		{ label: 'Website', fieldName: 'website', type: 'url' },
		{ label: 'Phone', fieldName: 'phone', type: 'phone' },
		{ label: 'Balance', fieldName: 'amount', type: 'currency' },
		{ label: 'CloseAt', fieldName: 'closeAt', type: 'date' },
	];
	tbldata = [{"name":"Name (0)","website":"www.salesforce.com","amount":12,"phone":"2006326216","closeAt":"2024-03-08T04:42:33.363Z"},{"name":"Name (1)","website":"www.salesforce.com","amount":36,"phone":"2360113668","closeAt":"2024-03-07T04:42:33.363Z"},{"name":"Name (2)","website":"www.salesforce.com","amount":43,"phone":"5371828729","closeAt":"2024-02-25T04:42:33.363Z"},{"name":"Name (3)","website":"www.salesforce.com","amount":36,"phone":"2714877179","closeAt":"2024-03-09T04:42:33.363Z"},{"name":"Name (4)","website":"www.salesforce.com","amount":47,"phone":"4715515710","closeAt":"2024-02-26T04:42:33.363Z"}];
	@track _api_id;
	@api assetRecordId;
	@api 
	get api_id(){
		return this._api_id;
	}
	set api_id(value){
		this._api_id = value;
	}

	connectedCallback(){
		this.callFunction();
	}

	async callFunction(){
		console.log('***callFunction-in');
		
		let res = await invokeCore(this._api_id, this.assetRecordId);
		console.log('***callFunction-success'+JSON.stringify(res));
		this.title=res.title;
		this.screenjson=res.screen;
		this.show=true;

		res.screen.forEach(screen => {
			// Extracting lTables from the current screen
			let lTables = screen.lTables;
		
			// Iterate over lTables to parse and transform the labels
			lTables.forEach(table => {
				// Transform the labels
				table.label = this.transformLabels(table.label);
				console.log('line 55: '+JSON.stringify(table.label));
			});
		});

		this.tblcolumns = res.screen[0].lTables[0].label;
		console.log('line 59: '+JSON.stringify(res));
		this.tableData = res.screen[0].lTables[0].value;
		this.isRenderDatatable  = this.tableData?.length > 0 ? true : false;
		console.log('parseed columsn: '+ JSON.stringify(this.tblcolumns));
		console.log('parseed tableData: '+ JSON.stringify(this.tableData));
	}

	transformLabels(labelString) {
		let labelsArray = labelString.split(',');
		let transformedArray = [];
	
		labelsArray.forEach(labelItem => {
			let [fieldName, label] = labelItem.split(':');
			transformedArray.push({
				label: label,
				fieldName: fieldName
			});
		});
	
		return transformedArray;
	}
}