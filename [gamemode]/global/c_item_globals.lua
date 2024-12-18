function hasSpaceForItem( ... )
	return exports["item-system"]:hasSpaceForItem(... )
end

function hasItem( element, itemID, itemValue )
	return exports["item-system"]:hasItem(element, itemID, itemValue )
end

function getItemName( itemID, itemValue, metadata )
	return exports["item-system"]:getItemName(itemID, itemValue, metadata )
end
