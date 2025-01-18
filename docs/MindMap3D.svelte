<script lang="ts">
    import { onMount, onDestroy, createEventDispatcher } from 'svelte';
    import * as THREE from 'three';
    import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
    import { DragControls } from 'three/examples/jsm/controls/DragControls.js';
    import { nodes as nodesStore } from '../stores/mindMapStore';
    import type { MindMapNode } from '$lib/types/mindmap';

    let animationFrameId: number;
    let container: HTMLDivElement;
    let scene: THREE.Scene;
    let camera: THREE.PerspectiveCamera;
    let renderer: THREE.WebGLRenderer;
    let orbitControls: OrbitControls;
    let dragControls: DragControls;
    let threeNodes: THREE.Mesh[] = [];
    let branches: Array<{
        branch: THREE.Mesh;
        startNode: THREE.Mesh;
        endNode: THREE.Mesh;
        textMesh: THREE.Mesh;
    }> = [];
    let isDragging = false;
    let isInitialized = false;

    const dispatch = createEventDispatcher();

    function isMesh(object: THREE.Object3D): object is THREE.Mesh {
        return 'geometry' in object && 'material' in object;
    }

    function disposeMaterial(material: THREE.Material | THREE.Material[]) {
        if (Array.isArray(material)) {
            material.forEach(m => m.dispose());
        } else {
            material.dispose();
        }
    }

    onMount(() => {
        if (!isInitialized) {
        init();
            isInitialized = true;
        }
    });

    onDestroy(() => {
        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
        }
        cleanup();
    });

    function cleanup() {
        if (renderer) {
            renderer.dispose();
        }
        if (orbitControls) {
            orbitControls.dispose();
        }
        if (dragControls) {
            dragControls.dispose();
        }
        // Clean up geometries and materials
        threeNodes.forEach(node => {
            if (isMesh(node)) {
                node.geometry.dispose();
                if (node.material) {
                    disposeMaterial(node.material);
                }
        }
    });
        branches.forEach(({ branch, textMesh }) => {
            if (isMesh(branch)) {
                branch.geometry.dispose();
                if (branch.material) {
                    disposeMaterial(branch.material);
                }
            }
            if (isMesh(textMesh)) {
                textMesh.geometry.dispose();
                if (textMesh.material) {
                    disposeMaterial(textMesh.material);
                }
            }
        });
    }

    function init() {
        if (!container) return;

        // Scene setup
            scene = new THREE.Scene();
        scene.background = new THREE.Color(0xcccccc);

        // Camera setup
        const aspect = container.clientWidth / container.clientHeight;
        camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
            camera.position.z = 10;

        // Renderer setup
            renderer = new THREE.WebGLRenderer({ 
                antialias: true,
                alpha: true
            });
            renderer.setSize(container.clientWidth, container.clientHeight);
            container.appendChild(renderer.domElement);

        // Controls setup
            orbitControls = new OrbitControls(camera, renderer.domElement);
        // orbitControls.enableDamping = true;
        // orbitControls.dampingFactor = 0.05;
            
            dragControls = new DragControls([], camera, renderer.domElement);
            setupDragControls();

        // Lighting setup
        const ambientLight = new THREE.AmbientLight(0x404040);
            scene.add(ambientLight);
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.5);
            directionalLight.position.set(1, 1, 1);
            scene.add(directionalLight);

        // Handle window resize
            const handleResize = () => {
            if (!container || !camera || !renderer) return;
                camera.aspect = container.clientWidth / container.clientHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(container.clientWidth, container.clientHeight);
            };
            window.addEventListener('resize', handleResize);

        // Start animation loop
        animate();
    }

    function setupDragControls() {
        if (!dragControls || !camera || !renderer) return;

        dragControls.dispose();
        dragControls = new DragControls(threeNodes, camera, renderer.domElement);

        dragControls.addEventListener('hoveron', function (event: any) {
            if (!orbitControls) return;
            orbitControls.enabled = false;
            const object = event.object;
            if (isMesh(object) && object.material && 'emissive' in object.material) {
                object.material.emissive.setHex(0x666666);
            }
        });

        dragControls.addEventListener('hoveroff', function (event: any) {
            if (!orbitControls) return;
            orbitControls.enabled = true;
            const object = event.object;
            if (isMesh(object) && object.material && 'emissive' in object.material) {
                object.material.emissive.setHex(0x000000);
            }
        });

        dragControls.addEventListener('dragstart', function (event: any) {
            if (!orbitControls) return;
            isDragging = true;
            orbitControls.enabled = false;
        });

        dragControls.addEventListener('drag', function () {
            if (isDragging) {
                updateBranches();
                updateNodePositions();
            }
        });

        dragControls.addEventListener('dragend', function () {
            if (!orbitControls) return;
            isDragging = false;
            orbitControls.enabled = true;
            updateNodePositions();
            updateBranches();
        });

        renderer.domElement.addEventListener('click', handleClick);
    }

    function handleClick(event: MouseEvent) {
        if (isDragging || !camera || !renderer) return;
        
        event.preventDefault();
        
        const rect = renderer.domElement.getBoundingClientRect();
        const mouse = new THREE.Vector2();
        mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

        const raycaster = new THREE.Raycaster();
        raycaster.setFromCamera(mouse, camera);

        const intersects = raycaster.intersectObjects(threeNodes, false);
        
        if (intersects.length > 0) {
            const clickedNode = intersects[0].object as THREE.Mesh;
            const nodeData = $nodesStore.find(n => n.id === clickedNode.userData.id);
            if (nodeData) {
                dispatch('nodeSelect', {
                    nodeId: nodeData.id,
                    position: {
                        x: clickedNode.position.x,
                        y: clickedNode.position.y,
                        z: clickedNode.position.z
                    },
                    nodeData
                });
            }
        }
    }

    function createNode(position: THREE.Vector3, nodeData: MindMapNode): THREE.Mesh {
        if (!scene) return;

        const nodeGeometry = new THREE.SphereGeometry(nodeData.isCenter ? 0.75 : 0.5, 32, 32);
        const nodeMaterial = new THREE.MeshPhongMaterial({ 
            color: nodeData.isCenter ? 0x4CAF50 : 0x00ff00,
            emissive: 0x000000,
            shininess: 100
        });
        const node = new THREE.Mesh(nodeGeometry, nodeMaterial);
        node.position.copy(position);
        node.userData = { 
            id: nodeData.id,
            parentId: nodeData.parentId,
            title: nodeData.title,
            description: nodeData.description,
            nodeType: nodeData.nodeType,
            isCenter: nodeData.isCenter
        };
        scene.add(node);
        threeNodes.push(node);
        
        if (nodeData.parentId !== null && !nodeData.isCenter) {
            const parentNode = threeNodes.find(n => n.userData.id === nodeData.parentId);
            if (parentNode) {
                createBranch(parentNode, node);
            }
        }
        
        setupDragControls();
        return node;
    }

    function createBranch(startNode: THREE.Mesh, endNode: THREE.Mesh) {
        if (!scene || !camera) return;

        const points = [];
        const startPoint = startNode.position;
        const endPoint = endNode.position;
        const midPoint = new THREE.Vector3().lerpVectors(startPoint, endPoint, 0.5);
        midPoint.y += 0.5; // Add a slight upward curve

        for (let i = 0; i <= 20; i++) {
            const t = i / 20;
            const point = new THREE.Vector3();
            point.x = startPoint.x * (1 - t) * (1 - t) + midPoint.x * 2 * (1 - t) * t + endPoint.x * t * t;
            point.y = startPoint.y * (1 - t) * (1 - t) + midPoint.y * 2 * (1 - t) * t + endPoint.y * t * t;
            point.z = startPoint.z * (1 - t) * (1 - t) + midPoint.z * 2 * (1 - t) * t + endPoint.z * t * t;
            points.push(point);
        }

        const branchGeometry = new THREE.TubeGeometry(
            new THREE.CatmullRomCurve3(points),
            20,
            0.05,
            8,
            false
        );

        const branchMaterial = new THREE.MeshPhongMaterial({ 
            color: 0xff0000,
            transparent: true,
            opacity: 0.7
        });

        const branch = new THREE.Mesh(branchGeometry, branchMaterial);
        scene.add(branch);
        
        // Create text for the branch with larger size
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 512; // Increased from 256
        canvas.height = 128; // Increased from 64
        
        if (context) {
            context.font = '48px Arial'; // Increased from 24px
            context.fillStyle = 'white';
            context.textAlign = 'center';
            // Use the end node's title for the branch text
            context.fillText(endNode.userData.title || '', canvas.width / 2, canvas.height / 2);
        }
        
        const texture = new THREE.CanvasTexture(canvas);
        const textMaterial = new THREE.MeshBasicMaterial({
            map: texture,
            transparent: true,
            side: THREE.DoubleSide,
            depthWrite: false // This helps prevent z-fighting
        });

        const textGeometry = new THREE.PlaneGeometry(2, 0.5); // Increased size
        const textMesh = new THREE.Mesh(textGeometry, textMaterial);

        // Position text above the branch
        const textPosition = new THREE.Vector3().lerpVectors(startPoint, endPoint, 0.5);
        textPosition.y += 0.5; // Increased offset
        textMesh.position.copy(textPosition);
        
        // Make text always face the camera
        scene.add(textMesh);
        branches.push({ branch, startNode, endNode, textMesh });
    }

    function updateBranches() {
        if (!camera) return;

        branches.forEach(({ branch, startNode, endNode, textMesh }) => {
            // Update branch geometry
            const points = [];
            const startPoint = startNode.position;
            const endPoint = endNode.position;
            const midPoint = new THREE.Vector3().lerpVectors(startPoint, endPoint, 0.5);
            midPoint.y += 0.5;

            for (let i = 0; i <= 20; i++) {
                const t = i / 20;
                const point = new THREE.Vector3();
                point.x = startPoint.x * (1 - t) * (1 - t) + midPoint.x * 2 * (1 - t) * t + endPoint.x * t * t;
                point.y = startPoint.y * (1 - t) * (1 - t) + midPoint.y * 2 * (1 - t) * t + endPoint.y * t * t;
                point.z = startPoint.z * (1 - t) * (1 - t) + midPoint.z * 2 * (1 - t) * t + endPoint.z * t * t;
                points.push(point);
            }

            const newGeometry = new THREE.TubeGeometry(
                new THREE.CatmullRomCurve3(points),
                20,
                0.05,
                8,
                false
            );

            branch.geometry.dispose();
            branch.geometry = newGeometry;

            // Update text content and position
            const canvas = document.createElement('canvas');
            const context = canvas.getContext('2d');
            canvas.width = 512;
            canvas.height = 128;
            
            if (context) {
                context.font = '48px Arial';
                context.fillStyle = 'white';
                context.textAlign = 'center';
                // Use the end node's title for the branch text
                context.fillText(endNode.userData.title || '', canvas.width / 2, canvas.height / 2);
            }
            
            if (textMesh.material instanceof THREE.MeshBasicMaterial) {
                const texture = new THREE.CanvasTexture(canvas);
                textMesh.material.map = texture;
                textMesh.material.needsUpdate = true;
            }

            const textPosition = new THREE.Vector3().lerpVectors(startPoint, endPoint, 0.5);
            textPosition.y += 0.5;
            textMesh.position.copy(textPosition);
            textMesh.lookAt(camera.position);
        });
    }

    function updateNodePositions() {
        threeNodes.forEach(node => {
            const storeNode = $nodesStore.find(n => n.id === node.userData.id);
            if (storeNode) {
                storeNode.x = node.position.x;
                storeNode.y = node.position.y;
                storeNode.z = node.position.z;
                }
            });
        nodesStore.set($nodesStore);
    }

    function animate() {
        if (!scene || !camera || !renderer || !orbitControls) return;
        
        animationFrameId = requestAnimationFrame(animate);
        orbitControls.update();
        
        // Update text orientations to face camera
        branches.forEach(({ textMesh }) => {
            if (textMesh) {
                textMesh.lookAt(camera.position);
            }
        });
        
        renderer.render(scene, camera);
    }

    export function initializeNodesFromStore(nodes: MindMapNode[]) {
        if (!scene) return;

        // Clear existing nodes and branches
        threeNodes.forEach(node => {
                scene.remove(node);
                if (isMesh(node)) {
                node.geometry.dispose();
                    if (node.material) {
                        disposeMaterial(node.material);
                    }
                }
            });
            
        branches.forEach(({ branch, textMesh }) => {
                scene.remove(branch);
            scene.remove(textMesh);
                if (isMesh(branch)) {
                branch.geometry.dispose();
                    if (branch.material) {
                        disposeMaterial(branch.material);
                    }
                }
            if (isMesh(textMesh)) {
                textMesh.geometry.dispose();
                if (textMesh.material) {
                    disposeMaterial(textMesh.material);
                    }
                }
            });

            threeNodes = [];
            branches = [];

        // Create new nodes
        nodes.forEach(nodeData => {
            const position = new THREE.Vector3(nodeData.x, nodeData.y, nodeData.z);
            createNode(position, nodeData);
        });

        setupDragControls();
    }

    export function addNodeToScene(nodeData: MindMapNode) {
        if (!scene) return;
        const position = new THREE.Vector3(nodeData.x, nodeData.y, nodeData.z);
        createNode(position, nodeData);
    }

    export function updateNode(nodeData: MindMapNode) {
        if (!scene) return;
        const node = threeNodes.find(n => n.userData.id === nodeData.id);
        if (node) {
            node.userData = {
                ...node.userData,
                title: nodeData.title,
                description: nodeData.description
            };
            
            // Update branch text if this node has a parent
            const branch = branches.find(b => b.endNode === node);
            if (branch) {
                const canvas = document.createElement('canvas');
                const context = canvas.getContext('2d');
                canvas.width = 256;
                canvas.height = 64;

                if (context) {
                    context.font = '24px Arial';
                    context.fillStyle = 'white';
                    context.textAlign = 'center';
                    context.fillText(nodeData.title || '', canvas.width / 2, canvas.height / 2);
                }

                const texture = new THREE.CanvasTexture(canvas);
                if (branch.textMesh.material instanceof THREE.MeshBasicMaterial) {
                    branch.textMesh.material.map = texture;
                    branch.textMesh.material.needsUpdate = true;
                }
            }
        }
    }
</script>

<div bind:this={container}></div>

<style>
    div {
        width: 100%;
        height: 100vh;
        background: rgba(204, 204, 204, 0.5);
    }
</style>