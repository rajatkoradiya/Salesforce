** Create credit note allocation line **

SBQQ.TriggerControl.disable();
try{
	blng__CreditNoteLine__c[] creditNoteLines = [select Id, Name, blng__InvoiceLine__c, blng__TotalAmount__c, CurrencyIsoCode 
	from blng__CreditNoteLine__c 
	where blng__CreditNote__c = 'a7tTq00000006JzIAI'
	and blng__TotalAmount__c > 0 and blng__Allocations__c = 0];


	blng__CreditNoteAllocation__c[] crAllocations = new list<blng__CreditNoteAllocation__c>();
	for(blng__CreditNoteLine__c crLine : creditNoteLines){
		blng__CreditNoteAllocation__c crAllocation = new blng__CreditNoteAllocation__c();
		crAllocation.blng__InvoiceLine__c = crLine.blng__InvoiceLine__c;
		crAllocation.blng__CreditNoteLine__c = crLine.Id;
		crAllocation.blng__Amount__c = crLine.blng__TotalAmount__c;
		crAllocation.blng__Type__c = 'Allocation';
		crAllocation.CurrencyIsoCode = crLine.CurrencyIsoCode;
		crAllocations.add(crAllocation);
	}

	if(crAllocations.size() > 0){
		insert crAllocations;
	}
} finally {
	SBQQ.TriggerControl.enable();
}
