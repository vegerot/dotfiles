#export GO111MODULE=on
export GOPROXY="https://go-mod-proxy.byted.org,https://proxy.golang.org,direct"
export GOPRIVATE="*.byted.org,*.everphoto.cn"
export GOSUMDB="sum.golang.google.cn"

function set_tiktok_email() {
        if [[ -d .git && ! $(grep -e "^email =" .git/sl/config 2>/dev/null) ]]; then
                sl config --local ui.email=Max.Coplan@Bytedance.com
        fi
}

set_tiktok_email
