package away3d.animators 
{
	import away3d.arcane;
	import away3d.core.base.*;
	import away3d.core.utils.*;
	
	import flash.geom.*;
	
	use namespace arcane;
	
	/**
	 * @author robbateman
	 */
	public class VertexAnimator extends Animator 
	{
		private var _frames:Vector.<Vector.<Vector3D>> = new Vector.<Vector.<Vector3D>>();
		private var _cframe:Vector.<Vector3D>;
		private var _nframe:Vector.<Vector3D>;
		private var _vertices:Vector.<Vertex> = new Vector.<Vertex>();
		private var _cPosition:Vector3D;
		private var _nPosition:Vector3D;
		
        protected override function updateTarget():void
        {
        }
		
        protected override function getDefaultFps():Number
		{
			return 10;
		}
		
        protected override function updateProgress(val:Number):void
        {
        	super.updateProgress(val);
        	
        	if (_currentFrame == _frames.length) {
        		_cframe = _nframe = _frames[uint(_currentFrame-1)];
        	} else {
	        	_cframe = _frames[_currentFrame];
	        	
	        	if (_currentFrame == _frames.length - 1) {
	        		if (loop)
	        			_nframe = _frames[uint(0)];
	        		else
	        			_nframe = _frames[_currentFrame];
	        	} else {
	        		_nframe = _frames[uint(_currentFrame+1)];
	        	}
        	}
        	
        	//update vertices
        	var i:uint = _vertices.length;
			if (interpolate) {
	        	while(i--) {
	        		_cPosition = _cframe[i];
	        		_nPosition = _nframe[i];
					_vertices[i].setValue(_cPosition.x*_invFraction + _nPosition.x*_fraction, _cPosition.y*_invFraction + _nPosition.y*_fraction, _cPosition.z*_invFraction + _nPosition.z*_fraction);
	        	}
			} else {
				while(i--) {
					_cPosition = _cframe[i];
					_vertices[i].setValue(_cPosition.x, _cPosition.y, _cPosition.z);
	        	}
        	}
		}
        
		public function get frames():Vector.<Vector.<Vector3D>>
		{
			return _frames;
		}
				
		/**
		 * Creates a new <code>VertexAnimator</code>
		 * 
		 * @param	target		[optional]	Defines the 3d object to which the animation is applied.
		 * @param	init		[optional]	An initialisation object for specifying default instance properties.
		 */
		public function VertexAnimator(target:Object3D = null, init:Object = null)
		{
			super(target, init);
			Debug.trace(" + VertexAnimator");
		}
        
		public function addFrame(frame:Vector.<Vector3D>):void
		{
			_frames.push(frame);
			_totalFrames = _frames.length;
		}
		
		public function addVertex(vertex:Vertex):void
		{
			_vertices.push(vertex);
		}
	}
}
