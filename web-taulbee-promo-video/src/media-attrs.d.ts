import "react";

declare module "react" {
  interface MediaHTMLAttributes<T> {
    defaultMuted?: boolean;
  }
}
