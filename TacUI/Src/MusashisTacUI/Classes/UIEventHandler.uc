//-----------------------------------------------------------
//	Class:	UIEventHandler
//	Author: Musashi
//	Wraps delegate to provide a standard way to allow multiple function handling the same signal,
//	and resolves the delegate-overwritting issue.
//-----------------------------------------------------------
class UIEventHandler extends Object;

var private array< delegate<SignalHandler> > Handlers;

public delegate SignalHandler(Object Source);

///
/// Instantiates this class.
///
public static function UIEventHandler CreateHandler()
{
	return new class'UIEventHandler';
}

///
/// Adds given handler if it wasn't already added, does nothing (but logging warning) otherwise.
///
function AddHandler(delegate<SignalHandler> Handler) {
	if(Handler == none) return;
	if(Handlers.Find(Handler) != INDEX_NONE) return;
	Handlers.AddItem(Handler);
}

///
/// Removes given handler if it was previously added, does nothing otherwise.
///
function RemoveHandler(delegate<SignalHandler> Handler)
{
	//`assert(Handlers.Find(Handler) != INDEX_NONE);
	Handlers.RemoveItem(Handler);
}

///
/// Removes all previously added handlers. 
///
function RemoveAllHandlers()
{
	Handlers.Length = 0;
}

///
/// Dispatches this signal, the handlers will be called by order of addition.
///
function Dispatch(Object Source)
{
	local array< delegate<SignalHandler> > HandlersCopy;
	local delegate<SignalHandler> Handler;

	switch(Handlers.Length) {
		case 0:
			break;
		case 1:
			Handler = Handlers[0];
			Handler(Source);
			break;
		default:
			// copy array so we can remove handlers while iterating in addition order
			foreach Handlers(Handler) {
				HandlersCopy.AddItem(Handler);
			}
			foreach HandlersCopy(Handler) {
				Handler(Source);
			}
			break;
	}
}
