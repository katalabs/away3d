package away3d.core.clip
{
	import away3d.arcane;
	import away3d.core.base.*;
	import away3d.core.geom.*;
	import away3d.core.session.*;
	import away3d.core.vos.*;
	
	import flash.utils.*;
	
	use namespace arcane;
	
    /**
    * Frustum Clipping
    */
    public class FrustumClipping extends Clipping
    {
    	private var _faceVOs:Vector.<FaceVO>;
    	private var _segmentVOs:Vector.<SegmentVO>;
    	private var _spriteVOs:Vector.<SpriteVO>;
    	private var _faceVO:FaceVO;
    	private var _segmentVO:SegmentVO;
    	private var _spriteVO:SpriteVO;
    	private var _v0C:VertexClassification;
    	private var _v1C:VertexClassification;
    	private var _v2C:VertexClassification;
    	private var _v0d:Number;
    	private var _v1d:Number;
    	private var _v2d:Number;
    	private var _v0w:Number;
    	private var _v1w:Number;
    	private var _v2w:Number;
    	private var _d:Number;
    	private var _session:AbstractSession;
    	private var _frustum:Frustum;
    	private var _processed:Dictionary;
    	private var _pass:Boolean;
		private var _v0:Vertex;
    	private var _v01:Vertex;
    	private var _v1:Vertex;
    	private var _v12:Vertex;
    	private var _v2:Vertex;
    	private var _v20:Vertex;
    	private var _uv0:UV;
    	private var _uv01:UV;
    	private var _uv1:UV;
    	private var _uv12:UV;
    	private var _uv2:UV;
    	private var _uv20:UV;
		
		public override function set objectCulling(val:Boolean):void
		{
			if (!val)
				throw new Error("objectCulling requires setting to true for FrustumClipping");
			
			_objectCulling = val;
		}
		
        public function FrustumClipping(init:Object = null)
        {
            super(init);
            
            objectCulling = ini.getBoolean("objectCulling", true);
        }
        
		public override function checkElements(mesh:Mesh, clippedFaceVOs:Vector.<FaceVO>, clippedSegmentVOs:Vector.<SegmentVO>, clippedSpriteVOs:Vector.<SpriteVO>, clippedVertices:Vector.<Vertex>, clippedVerts:Vector.<Number>, clippedIndices:Vector.<int>, startIndices:Vector.<int>):void
		{
			_session = mesh.session;
			_frustum = _cameraVarsStore.frustumDictionary[mesh];
			_processed = new Dictionary(true);
			
			
            _faceVOs = mesh.faceVOs;
            
			for each(_faceVO in _faceVOs)
			{
				if(true/*_faceVO.vertices.length == 3*/)
					checkNormalFace(_faceVO, clippedFaceVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
				else
					checkIrregularFace(_faceVO, clippedFaceVOs, clippedSegmentVOs, clippedSpriteVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
	        }
	        
			_segmentVOs = mesh.segmentVOs;
			
			for each(_segmentVO in _segmentVOs)
				checkNormalSegment(_segmentVO, clippedSegmentVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
	        
			_spriteVOs = mesh.spriteVOs;
	        
			for each(_spriteVO in _spriteVOs)
				checkNormalSprite(_spriteVO, clippedSpriteVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
	        
	        startIndices[startIndices.length] = clippedIndices.length;
		}
		
		/**
		 * Trying to add support for irregular shapes in FrustumClipping.
		 * WORK IN PROGRESS. 
		 */		
		private var _verticesC:Vector.<VertexClassification>;
		private var _distances:Array;
		private function checkIrregularFace(faceVO:FaceVO, clippedFaceVOs:Vector.<FaceVO>, clippedSegmentVOs:Vector.<SegmentVO>, clippedSpriteVOs:Vector.<SpriteVO>, clippedVertices:Vector.<Vertex>, clippedVerts:Vector.<Number>, clippedIndices:Vector.<int>, startIndices:Vector.<int>):void
		{
			clippedSegmentVOs; clippedSpriteVOs; clippedVerts;
			_pass = true;
			
			var i:uint;
				
			_verticesC = new Vector.<VertexClassification>();
			for(i = 0; i<_faceVO.vertices.length; i++)
				_verticesC.push(_cameraVarsStore.createVertexClassification(_faceVO.vertices[i]));
			
			/*_v0C = _cameraVarsStore.createVertexClassification(_faceVO.v0);
			_v1C = _cameraVarsStore.createVertexClassification(_faceVO.v1);
			_v2C = _cameraVarsStore.createVertexClassification(_faceVO.v2);*/
			
			var _plane:Plane3D;
			var matchIndex:int = -1;
			for(i = 0; i<_faceVO.vertices.length; i++)
			{
				_v0C = _verticesC[i];
				
				if(_v0C.plane)
				{
					_plane = _v0C.plane;
					matchIndex = i;
					break;
				}
			}
			
			_distances = [];
			var allDistancesAreLessThanZero:Boolean = true;
			var atLeastOneDistanceIsLessThanZero:Boolean = false;
			if(matchIndex != -1)
			{
				for(i = 0; i<_faceVO.vertices.length; i++)
				{
					_v0C = _verticesC[i];
					
					if(i == matchIndex)
						_distances.push(_v0C.distance);
					else
						_distances.push(_v0C.getDistance(_plane));
				}
				
				for(i = 0; i<_distances.length; i++)
				{
					if(_distances[i] >= 0)
						allDistancesAreLessThanZero = false;
					else if(_distances[i] < 0)
						atLeastOneDistanceIsLessThanZero = true;
				}
				
				if(allDistancesAreLessThanZero)
					return;
					
				if(atLeastOneDistanceIsLessThanZero)
					_pass = false;
			}
			else
			{
				var _frustum_planes:Vector.<Plane3D> = _frustum.planes;
				var _continue:Boolean = false;
				
				for each(_plane in _frustum_planes)
				{
					for(i = 0; i<_faceVO.vertices.length; i++)
					{
						_v0C = _verticesC[i];
						_distances.push(_v0C.getDistance(_plane));
					}
					
					allDistancesAreLessThanZero = true;
					atLeastOneDistanceIsLessThanZero = false;
					for(i = 0; i<_distances.length; i++)
					{
						if(_distances[i] >= 0)
							allDistancesAreLessThanZero = false;
						else if(_distances[i] < 0)
							atLeastOneDistanceIsLessThanZero = true;
					}
					
					if(allDistancesAreLessThanZero)
					{
						_continue = true;
						break;
					}
					
					if(atLeastOneDistanceIsLessThanZero)
					{
						_pass = false;
						break;
					}
				}
				
				if(_continue)
					return;
			}
			
			/*if(_v0C.plane || _v1C.plane || _v2C.plane)
			{
				if((_plane = _v0C.plane))
				{
					_v0d = _v0C.distance;
					_v1d = _v1C.getDistance(_plane);
					_v2d = _v2C.getDistance(_plane);
				}
				else if((_plane = _v1C.plane))
				{
					_v0d = _v0C.getDistance(_plane);
					_v1d = _v1C.distance;
					_v2d = _v2C.getDistance(_plane);
				}
				else if((_plane = _v2C.plane))
				{
					_v0d = _v0C.getDistance(_plane);
					_v1d = _v1C.getDistance(_plane);
					_v2d = _v2C.distance;
				}
				
				if(_v0d < 0 && _v1d < 0 && _v2d < 0)
					return;
				
				if(_v0d < 0 || _v1d < 0 || _v2d < 0)
					_pass = false;
			}
			else
			{
				var _frustum_planes:Array = _frustum.planes;
				var _continue:Boolean = false;
				
				for each(_plane in _frustum_planes)
				{
					_v0d = _v0C.getDistance(_plane);
					_v1d = _v1C.getDistance(_plane);
					_v2d = _v2C.getDistance(_plane);
					
					if(_v0d < 0 && _v1d < 0 && _v2d < 0)
					{
						_continue = true;
						break;
					}
					
					if(_v0d < 0 || _v1d < 0 || _v2d < 0)
					{
						_pass = false;
						break;
					}
				}
				
				if(_continue)
					return;
			}*/
			
			if(_pass)
			{
				clippedFaceVOs[clippedFaceVOs.length] = _faceVO;
				startIndices[startIndices.length] = clippedIndices.length;
				
				for each(var vertex:Vertex in _faceVO.vertices)
				{
					if(!_processed[vertex])
					{
	                    clippedVertices[clippedVertices.length] = vertex;
	                    clippedIndices[clippedIndices.length] = (_processed[vertex] = clippedVertices.length) - 1;
	                }
	                else
	                {
	                	clippedIndices[clippedIndices.length] = _processed[vertex] - 1;
	                }
				}
				
				return;
			}
			
			/*if(_pass)
			{
				clippedFaceVOs[clippedFaceVOs.length] = _faceVO;
				
				startIndices[startIndices.length] = clippedIndices.length;
        		
				if(!_processed[_faceVO.v0])
				{
                    clippedVertices[clippedVertices.length] = _faceVO.v0;
                    clippedIndices[clippedIndices.length] = (_processed[_faceVO.v0] = clippedVertices.length) - 1;
                }
                else
                {
                	clippedIndices[clippedIndices.length] = _processed[_faceVO.v0] - 1;
                }
                if(!_processed[_faceVO.v1])
                {
                    clippedVertices[clippedVertices.length] = _faceVO.v1;
                    clippedIndices[clippedIndices.length] = (_processed[_faceVO.v1] = clippedVertices.length) - 1;
                }
                else
                {
                	clippedIndices[clippedIndices.length] = _processed[_faceVO.v1] - 1;
                }
                if(!_processed[_faceVO.v2])
                {
                    clippedVertices[clippedVertices.length] = _faceVO.v2;
                    clippedIndices[clippedIndices.length] = (_processed[_faceVO.v2] = clippedVertices.length) - 1;
                }
                else
                {
                	clippedIndices[clippedIndices.length] = _processed[_faceVO.v2] - 1;
                }
                
				return;
			}*/
			
			var newVertices:Array = [];
			for(i = 0; i<_distances.length-1; i++)
			{
				_v0d = _distances[i];
				_v1d = _distances[i+1];
				
				if(!(_v0d >= 0 && _v1d < 0))
				{
					newVertices.push(_verticesC[i].vertex);
					//newVertices.push(_verticesC[i+1].vertex);
				}
				else
				{
					_d = (_v0d - _v1d);
					//newVertices.push(_verticesC[i].vertex);
					/*newVertices.push(_cameraVarsStore.createVertex((_verticesC[i+1].vertex.x*_v0d - _verticesC[i].vertex.x*_v1d)/_d,
																   (_verticesC[i+1].vertex.y*_v0d - _verticesC[i].vertex.y*_v1d)/_d,
																   (_verticesC[i+1].vertex.z*_v0d - _verticesC[i].vertex.z*_v1d)/_d));*/
				}
				
				/*if(i > 100)
					break;*/
			}
			
			/*if(_v0d >= 0 && _v1d < 0)
			{
				_v0w = _v0d;
				_v1w = _v1d;
				_v2w = _v2d;
				_v0 = _faceVO.v0;
    			_v1 = _faceVO.v1;
    			_v2 = _faceVO.v2;
    			_uv0 = _faceVO.uv0;
    			_uv1 = _faceVO.uv1;
    			_uv2 = _faceVO.uv2;
			}
			else if(_v1d >= 0 && _v2d < 0)
			{
				_v0w = _v1d;
				_v1w = _v2d;
				_v2w = _v0d;
				_v0 = _faceVO.v1;
    			_v1 = _faceVO.v2;
    			_v2 = _faceVO.v0;
    			_uv0 = _faceVO.uv1;
    			_uv1 = _faceVO.uv2;
    			_uv2 = _faceVO.uv0;
			}
			else if(_v2d >= 0 && _v0d < 0)
			{
				_v0w = _v2d;
				_v1w = _v0d;
				_v2w = _v1d;
    			_v0 = _faceVO.v2;
    			_v1 = _faceVO.v0;
    			_v2 = _faceVO.v1;
    			_uv0 = _faceVO.uv2;
    			_uv1 = _faceVO.uv0;
    			_uv2 = _faceVO.uv1;
			}*/
    		
        	/*_d = (_v0w - _v1w);
        	
        	_v01 = _cameraVarsStore.createVertex((_v1.x*_v0w - _v0.x*_v1w)/_d, (_v1.y*_v0w - _v0.y*_v1w)/_d, (_v1.z*_v0w - _v0.z*_v1w)/_d);
        	
        	_uv01 = _uv0? _cameraVarsStore.createUV((_uv1.u*_v0w - _uv0.u*_v1w)/_d, (_uv1.v*_v0w - _uv0.v*_v1w)/_d, _session) : null;
    		
        	if(_v2w < 0)
        	{
				_d = (_v0w - _v2w);
				
        		_v20 = _cameraVarsStore.createVertex((_v2.x*_v0w - _v0.x*_v2w)/_d, (_v2.y*_v0w - _v0.y*_v2w)/_d, (_v2.z*_v0w - _v0.z*_v2w)/_d);
        		
        		_uv20 = _uv0? _cameraVarsStore.createUV((_uv2.u*_v0w - _uv0.u*_v2w)/_d, (_uv2.v*_v0w - _uv0.v*_v2w)/_d, _session) : null;
        		
        		_newFaceVO = _faceVOs[_faceVOs.length] = _cameraVarsStore.createFaceVO(_faceVO.face, _faceVO.material, _faceVO.back,  _uv0, _uv01, _uv20);
        		_newFaceVO.vertices[0] = _newFaceVO.v0 = _v0;
        		_newFaceVO.vertices[1] = _newFaceVO.v1 = _v01;
        		_newFaceVO.vertices[2] = _newFaceVO.v2 = _v20;
        	}
        	else
        	{
        		_d = (_v2w - _v1w);
        		
        		_v12 = _cameraVarsStore.createVertex((_v1.x*_v2w - _v2.x*_v1w)/_d, (_v1.y*_v2w - _v2.y*_v1w)/_d, (_v1.z*_v2w - _v2.z*_v1w)/_d);
        		
        		_uv12 = _uv0? _cameraVarsStore.createUV((_uv1.u*_v2w - _uv2.u*_v1w)/_d, (_uv1.v*_v2w - _uv2.v*_v1w)/_d, _session) : null;
        		
        		_newFaceVO = _faceVOs[_faceVOs.length] = _cameraVarsStore.createFaceVO(_faceVO.face, _faceVO.material, _faceVO.back, _uv0, _uv01, _uv2);
        		_newFaceVO.vertices[0] = _newFaceVO.v0 = _v0;
        		_newFaceVO.vertices[1] = _newFaceVO.v1 = _v01;
        		_newFaceVO.vertices[2] = _newFaceVO.v2 = _v2;
        		
        		_newFaceVO = _faceVOs[_faceVOs.length] = _cameraVarsStore.createFaceVO(_faceVO.face, _faceVO.material, _faceVO.back, _uv01, _uv12, _uv2);
        		_newFaceVO.vertices[0] = _newFaceVO.v0 = _v01;
        		_newFaceVO.vertices[1] = _newFaceVO.v1 = _v12;
        		_newFaceVO.vertices[2] = _newFaceVO.v2 = _v2;
        	}*/
        	
        	var newFaceVO1:FaceVO = _faceVOs[_faceVOs.length] = _cameraVarsStore.createFaceVO(_faceVO.face, _faceVO.material, _faceVO.back);
    		for(i = 0; i<newVertices.length; i++)
    			newFaceVO1.vertices.push(newVertices[i]);
		}
		
		private function checkNormalFace(faceVO:FaceVO, clippedFaceVOs:Vector.<FaceVO>, clippedVertices:Vector.<Vertex>, clippedVerts:Vector.<Number>, clippedIndices:Vector.<int>, startIndices:Vector.<int>):void
		{
			_pass = true;
				
			_v0 = faceVO.vertices[0];
    		_v1 = faceVO.vertices[1];
    		_v2 = faceVO.vertices[2];
    		
			_v0C = _cameraVarsStore.createVertexClassification(_v0);
			_v1C = _cameraVarsStore.createVertexClassification(_v1);
			_v2C = _cameraVarsStore.createVertexClassification(_v2);
			
			var _plane:Plane3D;
			if(_v0C.plane || _v1C.plane || _v2C.plane)
			{
				if((_plane = _v0C.plane))
				{
					_v0d = _v0C.distance;
					_v1d = _v1C.getDistance(_plane);
					_v2d = _v2C.getDistance(_plane);
				}
				else if((_plane = _v1C.plane))
				{
					_v0d = _v0C.getDistance(_plane);
					_v1d = _v1C.distance;
					_v2d = _v2C.getDistance(_plane);
				}
				else if((_plane = _v2C.plane))
				{
					_v0d = _v0C.getDistance(_plane);
					_v1d = _v1C.getDistance(_plane);
					_v2d = _v2C.distance;
				}
				
				if(_v0d < 0 && _v1d < 0 && _v2d < 0)
					return;
				
				if(_v0d < 0 || _v1d < 0 || _v2d < 0)
					_pass = false;
			}
			else
			{
				var _frustum_planes:Vector.<Plane3D> = _frustum.planes;
				var _continue:Boolean = false;
				
				for each(_plane in _frustum_planes)
				{
					_v0d = _v0C.getDistance(_plane);
					_v1d = _v1C.getDistance(_plane);
					_v2d = _v2C.getDistance(_plane);
					
					if(_v0d < 0 && _v1d < 0 && _v2d < 0)
					{
						_continue = true;
						break;
					}
					
					if(_v0d < 0 || _v1d < 0 || _v2d < 0)
					{
						_pass = false;
						break;
					}
				}
				
				if(_continue)
					return;
			}
			
			if(_pass) {
				clippedFaceVOs[clippedFaceVOs.length] = faceVO;
				
				startIndices[startIndices.length] = clippedIndices.length;
        		
				if(!_processed[_v0]) {
                    clippedVertices[clippedVertices.length] = _v0;
                    clippedVerts.push(_v0.x, _v0.y, _v0.z);
                    clippedIndices[clippedIndices.length] = (_processed[_v0] = clippedVertices.length) - 1;
                } else {
                	clippedIndices[clippedIndices.length] = _processed[_v0] - 1;
                }
                if(!_processed[_v1]) {
                    clippedVertices[clippedVertices.length] = _v1;
                    clippedVerts.push(_v1.x, _v1.y, _v1.z);
                    clippedIndices[clippedIndices.length] = (_processed[_v1] = clippedVertices.length) - 1;
                } else {
                	clippedIndices[clippedIndices.length] = _processed[_v1] - 1;
                }
                if(!_processed[_v2]) {
                    clippedVertices[clippedVertices.length] = _v2;
                    clippedVerts.push(_v2.x, _v2.y, _v2.z);
                    clippedIndices[clippedIndices.length] = (_processed[_v2] = clippedVertices.length) - 1;
                } else {
                	clippedIndices[clippedIndices.length] = _processed[_v2] - 1;
                }
                
				return;
			}
			
			if(_v0d >= 0 && _v1d < 0) {
				_v0w = _v0d;
				_v1w = _v1d;
				_v2w = _v2d;
				_v0 = faceVO.vertices[0];
    			_v1 = faceVO.vertices[1];
    			_v2 = faceVO.vertices[2];
    			_uv0 = faceVO.uvs[0];
    			_uv1 = faceVO.uvs[1];
    			_uv2 = faceVO.uvs[2];
			} else if(_v1d >= 0 && _v2d < 0) {
				_v0w = _v1d;
				_v1w = _v2d;
				_v2w = _v0d;
				_v0 = faceVO.vertices[1];
    			_v1 = faceVO.vertices[2];
    			_v2 = faceVO.vertices[0];
    			_uv0 = faceVO.uvs[1];
    			_uv1 = faceVO.uvs[2];
    			_uv2 = faceVO.uvs[0];
			} else if(_v2d >= 0 && _v0d < 0) {
				_v0w = _v2d;
				_v1w = _v0d;
				_v2w = _v1d;
    			_v0 = faceVO.vertices[2];
    			_v1 = faceVO.vertices[0];
    			_v2 = faceVO.vertices[1];
    			_uv0 = faceVO.uvs[2];
    			_uv1 = faceVO.uvs[0];
    			_uv2 = faceVO.uvs[1];
			}
    		
        	_d = (_v0w - _v1w);
        	
        	_v01 = _cameraVarsStore.createVertex((_v1.x*_v0w - _v0.x*_v1w)/_d, (_v1.y*_v0w - _v0.y*_v1w)/_d, (_v1.z*_v0w - _v0.z*_v1w)/_d);
        	
        	_uv01 = _uv0? _cameraVarsStore.createUV((_uv1.u*_v0w - _uv0.u*_v1w)/_d, (_uv1.v*_v0w - _uv0.v*_v1w)/_d, _session) : null;
    		
        	if (_v2w < 0) {
				_d = (_v0w - _v2w);
				
        		_v20 = _cameraVarsStore.createVertex((_v2.x*_v0w - _v0.x*_v2w)/_d, (_v2.y*_v0w - _v0.y*_v2w)/_d, (_v2.z*_v0w - _v0.z*_v2w)/_d);
        		
        		_uv20 = _uv0? _cameraVarsStore.createUV((_uv2.u*_v0w - _uv0.u*_v2w)/_d, (_uv2.v*_v0w - _uv0.v*_v2w)/_d, _session) : null;
        		
        		var newFaceVO1:FaceVO = _cameraVarsStore.createFaceVO(faceVO.face, faceVO.material, faceVO.back);
        		newFaceVO1.vertices[0] = _v0;
        		newFaceVO1.vertices[1] = _v01;
        		newFaceVO1.vertices[2] = _v20;
        		newFaceVO1.uvs[0] = _uv0;
        		newFaceVO1.uvs[1] = _uv01;
        		newFaceVO1.uvs[2] = _uv20;
        		
        		checkNormalFace(newFaceVO1, clippedFaceVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
        	} else {
        		_d = (_v2w - _v1w);
        		
        		_v12 = _cameraVarsStore.createVertex((_v1.x*_v2w - _v2.x*_v1w)/_d, (_v1.y*_v2w - _v2.y*_v1w)/_d, (_v1.z*_v2w - _v2.z*_v1w)/_d);
        		
        		_uv12 = _uv0? _cameraVarsStore.createUV((_uv1.u*_v2w - _uv2.u*_v1w)/_d, (_uv1.v*_v2w - _uv2.v*_v1w)/_d, _session) : null;
        		
        		var newFaceVO2:FaceVO = _cameraVarsStore.createFaceVO(faceVO.face, faceVO.material, faceVO.back);
        		newFaceVO2.vertices[0] = _v0;
        		newFaceVO2.vertices[1] = _v01;
        		newFaceVO2.vertices[2] = _v2;
        		newFaceVO2.uvs[0] = _uv0;
        		newFaceVO2.uvs[1] = _uv01;
        		newFaceVO2.uvs[2] = _uv2;
        		
        		var newFaceVO3:FaceVO = _cameraVarsStore.createFaceVO(faceVO.face, faceVO.material, faceVO.back);
        		newFaceVO3.vertices[0] = _v01;
        		newFaceVO3.vertices[1] = _v12;
        		newFaceVO3.vertices[2] = _v2;
        		newFaceVO3.uvs[0] = _uv01;
        		newFaceVO3.uvs[1] = _uv12;
        		newFaceVO3.uvs[2] = _uv2;
        		
        		checkNormalFace(newFaceVO2, clippedFaceVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
        		checkNormalFace(newFaceVO3, clippedFaceVOs, clippedVertices, clippedVerts, clippedIndices, startIndices);
        	}
		}
		
		private function checkNormalSegment(segmentVO:SegmentVO, clippedSegmentVOs:Vector.<SegmentVO>, clippedVertices:Vector.<Vertex>, clippedVerts:Vector.<Number>, clippedIndices:Vector.<int>, startIndices:Vector.<int>):void
		{
			//always pass segments
			
			_v0 = segmentVO.vertices[0];
    		_v1 = segmentVO.vertices[1];
    		
			clippedSegmentVOs[clippedSegmentVOs.length] = segmentVO;
			
			startIndices[startIndices.length] = clippedIndices.length;
    		
			if(!_processed[_v0]) {
                clippedVertices[clippedVertices.length] = _v0;
                clippedVerts.push(_v0.x, _v0.y, _v0.z);
                clippedIndices[clippedIndices.length] = (_processed[_v0] = clippedVertices.length) - 1;
            } else {
            	clippedIndices[clippedIndices.length] = _processed[_v0] - 1;
            }
            if(!_processed[_v1]) {
                clippedVertices[clippedVertices.length] = _v1;
                clippedVerts.push(_v1.x, _v1.y, _v1.z);
                clippedIndices[clippedIndices.length] = (_processed[_v1] = clippedVertices.length) - 1;
            } else {
            	clippedIndices[clippedIndices.length] = _processed[_v1] - 1;
            }
		}
		
		private function checkNormalSprite(spriteVO:SpriteVO, clippedSpriteVOs:Vector.<SpriteVO>, clippedVertices:Vector.<Vertex>, clippedVerts:Vector.<Number>, clippedIndices:Vector.<int>, startIndices:Vector.<int>):void
		{
			//always pass segments
			
			_v0 = spriteVO.vertices[0];
    		
			clippedSpriteVOs[clippedSpriteVOs.length] = spriteVO;
			
			startIndices[startIndices.length] = clippedIndices.length;
    		
			if(!_processed[_v0]) {
                clippedVertices[clippedVertices.length] = _v0;
                clippedVerts.push(_v0.x, _v0.y, _v0.z);
                clippedIndices[clippedIndices.length] = (_processed[_v0] = clippedVertices.length) - 1;
            } else {
            	clippedIndices[clippedIndices.length] = _processed[_v0] - 1;
            }
		}
		
		/**
		 * @inheritDoc
		 */
        public override function rect(minX:Number, minY:Number, maxX:Number, maxY:Number):Boolean
        {
            if (this.maxX < minX)
                return false;
            if (this.minX > maxX)
                return false;
            if (this.maxY < minY)
                return false;
            if (this.minY > maxY)
                return false;

            return true;
        }
		
		public override function clone(object:Clipping = null):Clipping
        {
        	var clipping:FrustumClipping = (object as FrustumClipping) || new FrustumClipping();
        	
        	super.clone(clipping);
        	
        	return clipping;
        }
    }
}