function myIsLess(elt1::Elt, elt2::Elt)
	if elt1.idReq == elt2.idReq
		if elt1.state == E
			return false
		else 
			return elt2.state == E
		end
	else 
		return elt1.idReq < elt2.idReq
	end
end 
