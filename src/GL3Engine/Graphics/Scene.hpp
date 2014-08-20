#ifndef SCENE_HPP_
#define SCENE_HPP_
#include "Effects.hpp"
#include "MatrixStack.hpp"

namespace GL3Engine {
    class Drawable {
        public:
            virtual void draw()=0;
            virtual void passToShader() {
            }
            
            virtual ~Drawable() {
            }
    };
    class WindowEventListener {
        public:
            virtual GLboolean getMouseEvent(const Vec2i&, GLuint) {
                return false;
            }
            virtual GLboolean getKeyEvent(GLchar) {
                return false;
            }
            virtual ~WindowEventListener() {
            }
    };
    
    class SceneManager;
    class RenderTarget;
    
    class Node :
                 public Drawable,
                 public WindowEventListener {
            friend class SceneManager;
            template<typename U> friend class Batch;

        public:
            static constexpr GLfloat VIEW_DISTANCE = 6.f;
            enum class State {
                NORMAL,
                DISABLED,
                DESTROYED
            };

        protected:
            Node* parent = nullptr;
            SceneManager* scene = nullptr;
            MatrixStack* world = nullptr;

            Transform transform;
            Shader* effect = nullptr;
            GLuint render_mode = GL_TRIANGLES;
            State state = State::NORMAL;

            struct ShaderParam {
                    vector<GLfloat> data;
                    GLenum type;

                    GLfloat& operator[](GLuint index) {
                        return data[index];
                    }
            };
            map<string, ShaderParam> effect_params;

        public:
            Node& setRenderMode(GLuint render_mode) {
                this->render_mode = render_mode;
                return *this;
            }
            Transform& getTransform() {
                return transform;
            }
            
            ShaderParam& getShaderParam(c_str key) {
                return effect_params[key];
            }
            Node& setShaderParam(c_str, const ShaderParam&);
            Node& setEffect(Shader* effect) {
                this->effect = effect;
                return *this;
            }
            Shader* getEffect() {
                return effect;
            }
            
            Node* getParentNode() const {
                return parent;
            }
            SceneManager* getScene() const {
                return scene;
            }
            
            GLboolean isActive() const {
                return state == State::NORMAL;
            }
            Node& setState(State state) {
                this->state = state;
                return *this;
            }
            State getState() const {
                return state;
            }
            
            virtual inline size_t getHash()=0;

#define CLASS_HASH(T) \
            constHash(#T)
#define DECLARE_NODE_TYPE(T) \
            public: \
            inline size_t getHash() override { \
                return CLASS_HASH(T); \
            }

        private:
            Node& setParent(Node* parent) {
                this->parent = parent;
                return *this;
            }
            void update();
    };

    template<typename T>
    class Batch :
                  public Node {
        protected:
            vector<T*> objects;

        public:
            Batch& regObject(T& object) {
                if (is_base_of<Node, T>::value)
                    dynamic_cast<Node*>(&object)->setParent(this);
                objects.push_back(&object);
                return *this;
            }
    };
    class SceneManager :
                         public Drawable,
                         public WindowEventListener {
        public:
            enum class SceneFlag {
                LIGHT_SHADER_BINDING,
            };
            using SceneFlags = map<SceneManager::SceneFlag, GLuint>;
            using NodeList = vector<unique_ptr<Node>>;

        private:
            NodeList nodes;
            MatrixStack world_matrix;
            RenderTarget* target = nullptr;

            SceneFlags flags = {
                    { SceneFlag::LIGHT_SHADER_BINDING, 0 }
            };

        public:
            SceneManager(const Vec2i& res)
                    :
                      world_matrix(res) {
            }
            
            inline NodeList::iterator begin() {
                return nodes.begin();
            }
            inline NodeList::iterator end() {
                return nodes.end();
            }

            SceneManager& addSceneNode(Node*);
            template<typename T>
            T& createSceneNode() {
                static_assert(is_base_of<Node, T>::value, "Bad node type!");
                Node* node = new T;
                {
                    addSceneNode(node);
                }
                return *dynamic_cast<T*>(node);
            }
            SceneManager& setRenderTarget(RenderTarget* target) {
                this->target = target;
                return *this;
            }
            
            void draw() override;
            GLboolean getMouseEvent(const Vec2i&, GLuint) override;
            GLboolean getKeyEvent(GLchar) override;

            SceneFlags& getSceneFlags() {
                return flags;
            }
            MatrixStack& getWorldMatrix() {
                return world_matrix;
            }
            Camera* getActiveCam() const {
                return world_matrix.getActiveCamera();
            }
            const Vec2i& getRenderResolution() const {
                return world_matrix.getResolution();
            }
    };
}

#endif
