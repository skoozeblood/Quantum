function hasSpaceForItem( ... )
	return exports["item-system"]:hasSpaceForItem(... )
end

function hasItem( element, itemID, itemValue )
	return exports["item-system"]:hasItem(element, itemID, itemValue )
end

function giveItem( element, itemID, itemValue, metadata )
	return exports["item-system"]:giveItem(element, itemID, itemValue, false, true, metadata )
end

function takeItem( element, itemID, itemValue )
	return exports["item-system"]:takeItem(element, itemID, itemValue )
end
