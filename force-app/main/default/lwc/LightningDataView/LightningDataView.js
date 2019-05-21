import { LightningElement, wire, api, track } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import OBJ_VIP_ACCOUNT from '@salesforce/schema/Accounts_VIP__c';

export default class LightningDataView extends LightningElement {
    @api market;
    @api latitude;
    @api longitude;
    
    @track
    listUI;
    
    @track
    error;

    @track
    listViewName = 'All';

    @track
    listViewApiName = 'All';
    
    @track
    listViews = [];
      
    listSummary;

    displayColumns;
    data;

    @wire(getListUi, { objectApiName: OBJ_VIP_ACCOUNT })
    getLists({ error, data }) {
        console.log('getlistui. data', data);
        console.log('getlistui.error', error);
        if (data) {
            console.log('getlistui.data.lists', data.lists);
            this.listSummary = data;
            var listViews = [{label: '', value: ''}];
            data.lists.forEach(function(item) {
                console.log('item.label', item.apiName);
                listViews.push({label:item.label, id: item.id, value: item.apiName });                
            });
            this.listViews = listViews;
        } else {
            this.lists = [];
            this.listSummary = undefined;
            this.error = error;
        }
    };

    
    @wire(getListUi, {
        objectApiName: OBJ_VIP_ACCOUNT,
        listViewApiName: '$listViewName'
    })
    getListData({ data, error }) {
        console.log('[getListData] data', data);
        console.log('[getListData] error', error);
        if (data) {
            let component = this;

            this.listUI = data;
            this.errror = undefined;

            this.displayColumns = [];

            if (this.listUI.info.displayColumns) {
                for(var i = 0; i < data.info.displayColumns.length; i++) {
                    this.displayColumns.push({
                        'label':data.info.displayColumns[i].label,
                        'fieldName':data.info.displayColumns[i].fieldApiName,
                        'type':'text'
                    });
                }
            }

            var records = [];
            data.records.records.forEach(function(item) {
                var distance = Math.sin(component.latitude * Math.PI) * Math.sin(item.fields.Latitude__c * Math.PI) + Math.cos(component.latitude * Math.PI) * Math.cos(item.fields.Latitude__c * Math.PI) + Math.cos(Math.abs(component.longitude - item.fields.Longitude__c) * Math.PI);
                distance = Math.acos(distance) * 6370981.162;
                console.log(item.fields.Account__r.displayValue + ' distance', distance);
                if (distance < 50) {
                    var record = {};
                    for(var fld in item.fields) {
                        record[fld] = item.fields[fld].value;
                    }
    
                    records.push(record);
                }
            });

            this.data = records;
            console.log('[getListData] data', data);
        } else {
            this.listUI = undefined;
            this.error = error;
        }
    };
    
    connectedCallback() {
        if (navigator.geolocation) {
            var component = this;
            navigator.geolocation.getCurrentPosition(function(position) {
                component.latitude = position.coords.latitude;
                component.longitude = position.coords.longitude;
            });
        }
    }

    handleListViewChange(event) {
        console.log('[handleListViewChange] event', event.detail.value);
        //this.listViewName = event.detail.label;
        this.listViewApiName = event.detail.value;
        for(var i = 0; i < this.listViews.length; i++) {
            if (this.listViews[i].value == event.detail.value) {
                this.listViewName = this.listViews[i].label;
                break;
            }
        }
        console.log('[handleListViewChange] listViewId', this.listViewApiName);
        console.log('[handleListViewChange] listViewName', this.listViewName);
    }
}